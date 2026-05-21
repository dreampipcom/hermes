
# init 0 (shutdown)
#
# SCRAPBOOK: PRAGMA: EZSH SHELL PRAGMA DRAFT: Ergonomika ZSH: As an abstraction: e.g. I can reboot docker containers and perceive visual comfortable progress instead of crazy matrix logs, and interact with the real/physical world, all while glancing at my terminal and feeling psychologically safe that there is perceivable made progress.
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
	while true; do echo -n .; sleep 1; done | pv -s $1 * $HERMES-COOLDOWN-POINTER -S -F '%t %p' > /dev/null
}

log "dp::hermes::${HERMES-ENV}::(busy):: Shutdown. Are you sure?."
take 10 "dp::hermes::${HERMES-ENV}::shutdown::(busy):: Gracefully shutting down ${HERMES-ENV}."

cd auth
docker stop hermes-auth-ldap
docker rm hermes-auth-ldap
cd $root_dir

cd ingress
docker stop hermes-ingress-traefik hermes-ingress-grafana hermes-ingress-prometheus hermes-ingress-alert-manager hermes-ingress-node-exporter hermes-ingress-whoami # to sort
docker rm hermes-ingress-traefik hermes-ingress-grafana hermes-ingress-prometheus hermes-ingress-alert-manager hermes-ingress-node-exporter hermes-ingress-whoami # to sort
cd $root_dir

cd model
docker stop hermes-model-redis hermes-model-mariadb hermes-model-postgres # to sort
docker rm hermes-model-redis hermes-model-mariadb hermes-model-postgres # to sort
cd $root_dir

cd mail
docker stop hermes-mail-stalwart hermes-mail-bulwark hermes-mail-bulwark-proxy hermes-mail-postgres hermes-mail-mailserver
docker rm hermes-mail-stalwart hermes-mail-bulwark hermes-mail-bulwark-proxy hermes-mail-postgres hermes-mail-mailserver
cd $root_dir

cd cloud
docker stop hermes-cloud-nextcloud hermes-cloud-collabora # to sort
docker rm hermes-cloud-nextcloud hermes-cloud-collabora # to sort
cd $root_dir

cd chat
docker stop hermes-chat-synapse hermes-chat-element hermes-chat-postgres # to sort
docker rm hermes-chat-synapse hermes-chat-element hermes-chat-postgres # to sort
cd $root_dir

docker network rm hermes-net-weagle hermes-net-chat hermes-net-cloud hermes-net-mail hermes-net-model-all hermes-net-model-auth hermes-net-model-chat hermes-net-model-cloud

log "dp::hermes::${HERMES-ENV}::shutdown::(idle)::all good." 0
