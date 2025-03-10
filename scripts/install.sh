#!/bin/bash
# init install
echo -e "\033[0;62m\033[0;49;35m"
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

if [ "$1" == "install:prod" ]; then
	cp kubesec/prod/.env.*.private .
	log "dp::hermes::ci::(busy):: Installing on prod server: Deploying secrets."
	./scripts/deploy-secrets.sh install:prod
elif [ "$1" == "install:next" ]; then
	cp kubesec/next/.env.*.private .
	log "dp::hermes::ci::(busy):: Installing on next server: Deploying secrets."
	./scripts/deploy-secrets.sh install:next
else
	log "dp::hermes::mail::(busy):: Preparing Aemilia (Mail: DMS): Skipping installation, pleace specify environment."
fi

set -a && source .env.common.private && set +a

# sudo rm -rf /var/lib/rancher/k3s/server/manifests/traefik.yaml
# helm uninstall traefik traefik-crd -n kube-system
# sudo systemctl restart k3s


log "dp::hermes::ci::(busy):: Installing on server: installing dependencies." 2
ssh ${HERMES_REMOTE} "mkdir dp; \
											cd dp; \
											git clone https://github.com/dreampipcom/hermes.git; \
											mv ../.env.*.private hermes/; \
											cd hermes; \
											git checkout ${HERMES_REMOTE_BRANCH}; \
											git pull; \
											chmod +x ./scripts/install-deps.sh; \
											./scripts/install-deps.sh;
											"





log "dp::hermes::ci::(idle)::all good." 0
