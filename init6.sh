#!/bin/bash
# init 6 (reboot)
echo -e "\033[0;62m\033[0;49;35m"
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
	while true; do echo -n .; sleep 1; done | pv -s $1 * $HERMES_COOLDOWN_POINTER  -S -F '%t %p' > /dev/null
}

log "dp::hermes::${HERMES_ENV}::(busy):: Reboot. Are you sure?."
take 10 "dp::hermes::${HERMES_ENV}::reboot::(busy):: Gracefully rebooting: shutting down ${HERMES_ENV}."

./init0.sh

log "dp::hermes::${HERMES_ENV}::reboot::(busy):: Gracefully rebooting: booting up ${HERMES_ENV}."

./init.sh


log "dp::hermes::${HERMES_ENV}::reboot::(idle)::all good." 0
