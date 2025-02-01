#!/bin/bash
# init emailia
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
# ./deploy-secrets.sh install


log "dp::hermes::ci::(busy):: Installing on server." 2
ssh ${HERMES_REMOTE} "mkdir dp; \
											cd dp; \
											mv ../.env.install.gh.private ../.ssh/gh; \
											mv ../.env.install.gitconfig.private ../.ssh/config; chmod 0600 ../.ssh/gh; \
											mv ../.env.*.private hermes; git clone git@github.com:dreampipcom/hermes.git; \
											sudo apt-get update; \
											sudo apt-get install ca-certificates curl; \
											sudo install -m 0755 -d /etc/apt/keyrings; \
											sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; \
											sudo chmod a+r /etc/apt/keyrings/docker.asc; \
											echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null sudo apt-get update; \
											sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; \
											curl -L https://github.com/kubernetes/kompose/releases/download/v1.34.0/kompose-linux-amd64 -o kompose; \
											chmod +x kompose; \
											sudo mv ./kompose /usr/local/bin/kompose;
											"



log "dp::hermes::ci::(idle)::all good." 0
