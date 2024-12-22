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

log "dp::hermes::(busy)::preparing Hermes Matrix Synapsis configuration files."

docker run -it --rm \
    --mount type=volume,src=synapse-data,dst=/data \
    -e SYNAPSE_SERVER_NAME=dpip.cc \
    -e SYNAPSE_REPORT_STATS=yes \
    matrixdotorg/synapse:latest generate

cp -r /var/lib/docker/volumes/synapse-data/_data .
cp -r ./_data/* ./matrix/server/files/

log "dp::hermes::(idle)::all good." 0