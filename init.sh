#!/bin/bash
# init.sh
echo -e "\033[0;62m\033[0;49;35m"
set -a && source .env && set +a
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
log "dp::hermes::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=10.10.10.0/24 \
  --gateway=10.10.10.1 \
  --attachable \
  matrix_network


# dir setup
log "dp::hermes::(busy)::creating folder structure."
cd ./matrix/server
gosu
mkdir data
sudo chmod -R a+rw data
sudo chown $(whoami):docker data
cd $root_dir


# prepare config
echo "dp::hermes::(busy)::preparing Hermes Matrix Infrastructure configuration files."
origin="./matrix/server/_docker-compose.yml"
destination="./matrix/server/docker-compose.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

log "dp::hermes::(busy)::preparing Hermes Matrix Home Server configuration files."
origin="./matrix/server/files/_homeserver.yml"
destination="./matrix/server/files/homeserver.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

log "dp::hermes::(busy)::preparing Hermes Matrix Client configuration files."
origin="./matrix/server/_element-config.json"
destination="./matrix/server/element-config.json"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination
cd $root_dir

log "dp::hermes::(idle)::all good." 0
