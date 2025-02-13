#!/bin/bash
# init emailia
echo -e "\033[0;62m\033[0;49;35m"
set -a && source .env.common.private && set +a
set -a && source .env.mail.private && set +a
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
	while true; do echo -n .; sleep 1; done | pv -s $1  -S -F '%t %p' > /dev/null
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
		echo $HERMES_MAIL_S3_KEY:$HERMES_MAIL_S3_SECRET > ~/.passwd-s3fs
		log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Mailboxes created." 0
}

log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS) configuration files." 2
origin="./mail/_docker-compose.yml"
destination="./mail/docker-compose.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

# dir setup
take 5 "dp::hermes::mail::(busy):: Launching Docker Compose Swarms."

cd mail
docker compose up -d
cd $root_dir

# log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS) Installing setup CLI." 2
# wget https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master/setup.sh
# chmod a+x ./setup.sh

# log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS) Adding mailboxes." 2
# ./setup.sh email add $HERMES_MAIN_MAILBOX



if [ "$1" == "setup:dns" ]; then
	for domain in ${HERMES_MAIL_DOMAINS//,/ }
	do
	    setup_dns $domain
	done
else
	log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Skipping DNS setup."
fi

if [ "$1" == "setup:mailboxes" ]; then
	for box in ${HERMES_MAIL_INITIAL_BOXES//,/ }
	do
	    setup_mailbox $box $HERMES_MAIL_INITIAL_BOXES_DEFAULT_PASSWORD
	done
else
	log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Skipping Mailboxes setup."
fi

log "dp::hermes::mail::(idle)::all good." 0
