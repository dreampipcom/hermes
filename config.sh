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
log "dp::hermes::(busy)::Installing req deps."
sudo apt-get install python3-venv libpq-dev

log "dp::hermes::(busy)::preparing Hermes Matrix Synapsis configuration files."
echo $HERMES_SERVER_NAME

data_dir="./matrix/server/data"
files_dir="./matrix/server/files"

docker run -it --rm \
    --mount type=volume,src=synapse-data,dst=/data \
    -e SYNAPSE_SERVER_NAME=$HERMES_SERVER_NAME \
    -e SYNAPSE_REPORT_STATS=yes \
    matrixdotorg/synapse:latest generate

cp -r /var/lib/docker/volumes/synapse-data/_data .
cp -r ./_data/* $files_dir


log "dp::hermes::(busy)::setting permissions."
sudo chmod -R a+rw $data_dir
sudo chown $(whoami):docker $data_dir
sudo chmod -R a+rw $files_dir
sudo chown $(whoami):docker $files_dir


log "dp::hermes::(busy)::cleaning up dangling files."
rm -r ./_data
rm -r /var/lib/docker/volumes/synapse-data/_data/*

log "dp::hermes::(idle)::all good." 0