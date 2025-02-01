#!/bin/bash
# init maivis
echo -e "\033[0;62m\033[0;49;35m"
set -a && source .env.matrix.private && set +a
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

# docker setup

# dir setup
log "dp::hermes::hermes_cloud::(busy)::creating folder structure."
cd ./chat/server
mkdir data
mkdir data/bridge
mkdir data/bridge/whatsapp
mkdir data/bridge/telegram
mkdir data/bridge/signal
mkdir data/bridge/discord
mkdir data/bridge/slack
mkdir data/bridge/meta
mkdir data/bridge/meta/instagram
mkdir data/bridge/meta/messenger
mkdir files
cd $root_dir

# prepare config
echo "dp::hermes::hermes_cloud::(busy)::preparing Maevis (Chat: Matrix) configuration files."
origin="./chat/server/_docker-compose.yml"
destination="./chat/server/docker-compose.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
UID=$(whoami)
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

# log "dp::hermes::hermes_cloud::(busy)::preparing Hermes Matrix Home Server configuration files."
# origin="./chat/server/files/_homeserver.yml"
# destination="./chat/server/files/homeserver.yml"
# tmpfile=$(mktemp)
# cp -p $origin $tmpfile
# cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

log "dp::hermes::hermes_cloud::(busy)::preparing Hermes Matrix Client configuration files."
origin="./chat/server/_element-config.json"
destination="./chat/server/element-config.json"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination
cd $root_dir


log "dp::hermes::hermes_cloud::(idle)::all good." 0
