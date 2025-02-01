#!/bin/bash
# init install
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
	while true; do echo -n .; sleep 1; done | pv -s $1  -S -F '%t %p' > /dev/null
}

log "dp::hermes::ci::(busy):: Installing on server: Deploying secrets."
./deploy-secrets.sh install

# sudo rm -rf /var/lib/rancher/k3s/server/manifests/traefik.yaml
# helm uninstall traefik traefik-crd -n kube-system
# sudo systemctl restart k3s

log "dp::hermes::ci::(busy):: Installing on server: installing dependencies." 2
ssh ${HERMES_REMOTE} "mkdir dp; \
											cd dp; \
											git clone https://github.com/dreampipcom/hermes.git; \
											mv ../.env.*.private hermes/; \
											sudo apt-get update; \
											sudo apt-get install -y docker.io pv ca-certificates curl; \
											curl -L https://github.com/kubernetes/kompose/releases/download/v1.34.0/kompose-linux-amd64 -o kompose; \
											chmod +x kompose; \
											sudo mv ./kompose /usr/local/bin/kompose;
											"





log "dp::hermes::ci::(idle)::all good." 0
