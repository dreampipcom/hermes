#!/bin/bash
set -euo pipefail
# init emailia
echo -e "\033[0;62m\033[0;49;35m"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a && source "$script_dir/.env.common.private" && set +a
set -a && source "$script_dir/.env.mail.private" && set +a
root_dir="$script_dir"
S3_MOUNT_MAX_RETRIES=10

log () {
	local level="${2:-}"
	echo -e "\033[0;49;35m"
	# warning
	if [[ "$level" == "2" ]]; then
		echo -e "\033[35;43m$1\033[0m"
	fi
	# error
	if [[ "$level" == "1" ]]; then
		echo -e "\033[35;41m\033[33m$1\033[0m"
	fi
	# success
	if [[ "$level" == "0" ]]; then
		echo -e "\033[35;42m$1\033[0m"
	fi
	# normal
	if [[ "$level" == "" ]]; then
		echo -e "\033[35;46m$1\033[0m"
	fi
}

prompt () {
	log "$1" 2
	read answer
	echo "$answer"
}

gosu () {
	if [ $( id -u ) -ne 0 ]; then
		log "dp::(auth)::this command needs sudo, please add password for %p: " 2
	    sudo -v
	    # exit $?
	fi
}

take () {
	log "dp::(idle)::let's wait $1 seconds for $2." 2
	while true; do echo -n .; sleep 1; done | pv -s $1  -S -F '%t %p' > /dev/null
}

require_env () {
	local name="$1"
	if [[ -z "${!name:-}" ]]; then
		log "dp::hermes::mail::(error)::Missing required environment variable: $name" 1
		exit 1
	fi
}

validate_mail_env () {
	for name in \
		HERMES_HOSTNAME \
		HERMES_APEX \
		HERMES_CERT_FILE \
		HERMES_CERT_KEY_FILE \
		HERMES_MAIL_CERT_TYPE \
		HERMES_DNS_RESOLVER \
		HERMES_PORT_PREFIX \
		HERMES_MAIL_MAIN_HOSTNAME \
		HERMES_MAIL_DOMAINS
	do
		require_env "$name"
	done
}

setup_dns () {
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): DNS Setup: Generating DKIMS." 2
		docker exec -it hermes-mail-mailserver setup config dkim domain $1
		docker exec -it hermes-mail-mailserver cat /tmp/docker-mailserver/opendkim/keys/$1/mail.txt >> ZONEFILE.$1.private
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): DKIM generated, check the ZONEFILE for this domain in the dir system." 0
}

setup_mailbox () {
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Mailbox Setup: Creating initial mailboxes." 2
		docker exec -it hermes-mail-mailserver setup email add $1@$HERMES_MAIL_MAIN_HOSTNAME $2
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Mailboxes created." 0
}

setup_storage () {
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Mailbox Setup: Preparing cloud email storage." 2
		require_env HERMES_MAIL_S3_BUCKET
		require_env HERMES_MAIL_S3_HOST
		require_env HERMES_MAIL_S3_KEY
		require_env HERMES_MAIL_S3_SECRET
		echo $HERMES_MAIL_S3_KEY:$HERMES_MAIL_S3_SECRET > ~/.passwd-s3fs
		chmod 600 ~/.passwd-s3fs
		mkdir -p "$root_dir/mail/data/email-data"
		touch "$root_dir/mail/data/email-data/dummy"
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Cloud email storage ready." 0
}

init_storage () {
		command -v s3fs >/dev/null 2>&1 || {
			log "dp::hermes::mail::(error)::s3fs is required for setup:storage." 1
			exit 1
		}
		take 2 "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Mailbox Setup: Fusing S3 bucket."
		if ! mountpoint -q "$root_dir/mail/data/email-data"; then
			s3_mount_log="$root_dir/mail/data/email-data/.s3fs.log"
			s3fs $HERMES_MAIL_S3_BUCKET "$root_dir/mail/data/email-data" -o nonempty -o passwd_file=~/.passwd-s3fs -o use_path_request_style -o url=https://${HERMES_MAIL_S3_HOST} >"$s3_mount_log" 2>&1 &
			for _ in $(seq 1 "$S3_MOUNT_MAX_RETRIES")
			do
				if mountpoint -q "$root_dir/mail/data/email-data"; then
					break
				fi
				sleep 1
			done
		fi
		mountpoint -q "$root_dir/mail/data/email-data" || {
			if [[ -s "${s3_mount_log:-}" ]]; then
				log "dp::hermes::mail::(error)::Cloud email storage mount log: $(tail -n 1 "$s3_mount_log")" 1
			fi
			log "dp::hermes::mail::(error)::Cloud email storage mount failed." 1
			exit 1
		}
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Cloud email storage mounted." 0
}

validate_mail_env
mkdir -p "$root_dir/mail/data/dms/mail-state" "$root_dir/mail/data/dms/mail-logs" "$root_dir/mail/data/dms/config" "$root_dir/mail/data/email-data"

log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS) configuration files." 2
origin="$root_dir/mail/_docker-compose.yml"
destination="$root_dir/mail/docker-compose.yml"
tmpfile=$(mktemp --tmpdir="$root_dir")
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination



if [ "${1:-}" == "setup:storage" ]; then
	setup_storage
	init_storage
else
	log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Skipping Storage setup, using local mail/data/email-data."
fi


# dir setup
take 5 "dp::hermes::mail::(busy):: Launching Docker Compose Swarms."

cd "$root_dir/mail"
docker compose up -d
cd "$root_dir"

# log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS) Installing setup CLI." 2
# wget https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master/setup.sh
# chmod a+x ./setup.sh

# log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS) Adding mailboxes." 2
# ./setup.sh email add $HERMES_MAIN_MAILBOX

if [ "${1:-}" == "setup:dns" ]; then
	for domain in ${HERMES_MAIL_DOMAINS//,/ }
	do
	    setup_dns $domain
	done
else
	log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Skipping DNS setup."
fi

if [ "${1:-}" == "setup:mailboxes" ]; then
	require_env HERMES_MAIL_INITIAL_BOXES
	require_env HERMES_MAIL_INITIAL_BOXES_DEFAULT_PASSWORD
	for box in ${HERMES_MAIL_INITIAL_BOXES//,/ }
	do
	    setup_mailbox $box $HERMES_MAIL_INITIAL_BOXES_DEFAULT_PASSWORD
	done
else
	log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Skipping Mailboxes setup."
fi

log "dp::hermes::mail::(idle)::all good." 0
