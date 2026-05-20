#!/bin/bash
set -euo pipefail
# init mail
echo -e "\033[0;62m\033[0;49;35m"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a && source "$script_dir/.env.common.private" && set +a
set -a && source "$script_dir/.env.cloud.private" && set +a
root_dir="$script_dir"

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
		log "dp::hermes::cloud::(error)::Missing required environment variable: $name" 1
		exit 1
	fi
}

validate_cloud_env () {
	for name in \
		HERMES_HOSTNAME \
		HERMES_CLOUD_BASEPATH \
		HERMES_CLOUD_DB_NAME \
		HERMES_CLOUD_DB_USER \
		HERMES_CLOUD_DB_PASS \
		HERMES_CLOUD_DB_HOST \
		HERMES_CLOUD_DB_REDIS \
		HERMES_DNS_RESOLVER \
		HERMES_INGRESS_SUBNET
	do
		require_env "$name"
	done
}

# Cloud
validate_cloud_env
mkdir -p "$root_dir/cloud/data/cloud/html" "$root_dir/cloud/data/cloud/custom_apps" "$root_dir/cloud/data/cloud/config" "$root_dir/cloud/data/cloud/data"

log "dp::hermes::hermes_net_cloud::(busy):: Preparing Claudia (Storage, Calendar, Mail Web Client: Nextcloud)." 2

log "dp::hermes::hermes_net_cloud::(busy):: Preparing Claudia: Consolidating files."
origin="$root_dir/cloud/_docker-compose.yml"
destination="$root_dir/cloud/docker-compose.yml"
tmpfile=$(mktemp --tmpdir="$root_dir")
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

log "dp::hermes::hermes_net_cloud::(busy):: Preparing Claudia: Consolidating files."
cloud_config_destination="$root_dir/cloud/data/cloud/config/hermes.config.php"
envsubst '${HERMES_CLOUD_BASEPATH} ${HERMES_HOSTNAME} ${HERMES_CLOUD_DB_REDIS} ${HERMES_INGRESS_SUBNET}' \
	< "$root_dir/cloud/_config.php" > "$cloud_config_destination"
if [[ ! -s "$cloud_config_destination" ]]; then
	log "dp::hermes::cloud::(error)::Failed to generate $cloud_config_destination" 1
	exit 1
fi

# dir setup
take 5 "dp::hermes::hermes_net_cloud::(busy):: Launching Docker Compose Swarms."


cd "$root_dir/cloud"
docker compose up -d
cd "$root_dir"

log "dp::hermes::hermes_net_cloud::(idle)::all good." 0
