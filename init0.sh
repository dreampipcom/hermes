#!/bin/bash
# init 0 (shutdown)
#
# SCRAPBOOK: PRAGMA: EZSH SHELL PRAGMA DRAFT: Ergonomika ZSH: As an abstraction: e.g. I can reboot docker containers and perceive visual comfortable progress instead of crazy matrix logs, and interact with the real/physical world, all while glancing at my terminal and feeling psychologically safe that there is perceivable made progress.
echo -e "\033[0;62m\033[0;49;35m"
cp .env.auth.private .env
set -a && source .env && set +a
set -a && source .env.common.private && set +a
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

log "dp::hermes::${HERMES_ENV}::(busy):: Shutdown. Are you sure?."
take 10 "dp::hermes::${HERMES_ENV}::shutdown::(busy):: Gracefully shutting down ${HERMES_ENV}."


cd auth
docker stop ldap
docker rm ldap
cd $root_dir

cd ingress
docker stop traefik2 grafana prometheus alert-manager node-explorer # to sort
docker rm traefik2 grafana prometheus alert-manager node-explorer # to sort
cd $root_dir

cd mail
docker stop mailserver
docker rm mailserver
cd $root_dir

cd cloud
docker stop nextcloud2 redis2 collabora # to sort
docker rm nextcloud2 redis2 collabora # to sort
cd $root_dir

cd chat
docker stop synapse element postgres # to sort
docker rm synapse element postgres # to sort
cd $root_dir


log "dp::hermes::${HERMES_ENV}::shutdown::(idle)::all good." 0
