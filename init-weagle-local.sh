#!/bin/bash
# init weagle
echo -e "\033[0;62m\033[0;49;35m"
cp .env.ingress.local.private .env
set -a && source .env.common.local.private && set +a
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
log "dp::hermes::hermes_weagle::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=129.101.0.0/24 \
  --gateway=129.101.0.1 \
  --attachable \
  weagle

log "dp::hermes::hermes_weagle::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=129.101.101.0/24 \
  --gateway=129.101.101.1 \
  --attachable \
  mail

# docker setup
log "dp::hermes::hermes_weagle::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=129.101.102.0/24 \
  --gateway=129.101.102.1 \
  --attachable \
  cloud

log "dp::hermes::hermes_weagle::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=129.102.103.0/24 \
  --gateway=129.102.103.1 \
  --attachable \
  matrix



log "dp::hermes::hermes_weagle::(busy)::preparing Weagle (Ingress: Traefik, Grafana, Prometheus) configuration files." 2
origin="./ingress/_docker-compose-local.yml"
destination="./ingress/docker-compose.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_traefik-local.yml"
destination="./ingress/traefik.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_dynamic-local.yml"
destination="./ingress/dynamic.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_prometheus.yml"
destination="./ingress/prometheus.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_alertmanager.yml"
destination="./ingress/alertmanager.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination


# dir setup
log "dp::hermes::hermes_weagle::(busy)::creating folder structure."
cd ingress
mkdir data
cd data
mkdir traefik
cd traefik
# dir setup
log "dp::hermes::hermes_weagle::(busy):: Creating (localhost) .PEM certificates (Snakeoil)." 2
mkcert $HERMES_HOSTNAME
cd $root_dir

take 5 "dp::hermes::hermes_weagle::(busy):: Launching Docker Compose Swarms."
cd ingress

# docker pull ghcr.io/dreampipcom/${HERMES_REPO}:main

# docker stop ${}

# docker rm hypnos

# docker run -d --name hypnos --restart unless-stopped -p 3001:3001 ghcr.io/dreampipcom/hypnos:main

docker compose up -d
cd $root_dir


log "dp::hermes::hermes_weagle::(idle)::all good." 0
