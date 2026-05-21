#!/bin/bash
# init emailia
echo -e "\033[0;62m\033[0;49;35m"

load_env () {
	local private_env=$1
	local public_env=$2
	if [ -f "$private_env" ]; then
		set -a && source "$private_env" && set +a
	else
		set -a && source "$public_env" && set +a
	fi
}

load_env .env.common.private .env.common.public
load_env .env.mail.private .env.mail.public
root_dir="$(pwd)"

log () {
	echo -e "\033[0;49;35m"
	# warning
	if [[ "$2" == "2" ]]; then
		echo -e "\033[35;43m$1\033[0m"
	fi
	# error
	if [[ "$2" == "1" ]]; then
		echo -e "\033[35;41m\033[33m$1\033[0m"
	fi
	# success
	if [[ "$2" == "0" ]]; then
		echo -e "\033[35;42m$1\033[0m"
	fi
	# normal
	if [[ "$2" == "" ]]; then
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
	if command -v pv > /dev/null 2>&1; then
		while true; do echo -n .; sleep 1; done | pv -s $1  -S -F '%t %p' > /dev/null
	else
		sleep "$1"
	fi
}

prepare_directories () {
		mkdir -p mail/data/stalwart/etc
		mkdir -p mail/data/stalwart/data
		mkdir -p mail/data/bulwark/admin
		mkdir -p mail/data/bulwark/admin-state
		mkdir -p mail/data/bulwark/settings
		mkdir -p mail/archive
}

archive_legacy_docker_mailserver () {
		legacy_dms_dir=mail/data/dms
		legacy_maildir=mail/data/email-data

		if [ -d "$legacy_dms_dir" ] || [ -d "$legacy_maildir" ]; then
			archive_dir=mail/archive/docker-mailserver-$(date -u +%Y%m%dT%H%M%SZ)
			mkdir -p "$archive_dir"
			[ -d "$legacy_dms_dir" ] && mv "$legacy_dms_dir" "$archive_dir/dms"
			[ -d "$legacy_maildir" ] && mv "$legacy_maildir" "$archive_dir/email-data"
			log "dp::hermes::mail::(busy):: Archived legacy docker-mailserver data to $archive_dir." 0
		else
			log "dp::hermes::mail::(busy):: No legacy docker-mailserver data detected." 0
		fi
}

log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: Stalwart/Bulwark) configuration files." 2
origin="./mail/_docker-compose.yml"
destination="./mail/docker-compose.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

prepare_directories
archive_legacy_docker_mailserver

if [ "$1" != "" ]; then
	log "dp::hermes::mail::(busy):: '$1' is deprecated for the Stalwart/Bulwark stack. Finish the bootstrap flow at ${HERMES_MAIL_SERVER_URL}/admin and create domains/mailboxes there." 2
fi


# dir setup
take 5 "dp::hermes::mail::(busy):: Launching Docker Compose Swarms."

cd mail
docker compose up -d --remove-orphans
cd $root_dir

log "dp::hermes::mail::(busy):: Stalwart admin available at ${HERMES_MAIL_SERVER_URL}/admin." 0
log "dp::hermes::mail::(busy):: Bulwark webmail available at http://localhost:${HERMES_PORT_PREFIX}20." 0
log "dp::hermes::mail::(idle)::all good." 0
