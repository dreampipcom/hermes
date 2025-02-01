#!/bin/bash
# init weagle
echo -e "\033[0;62m\033[0;49;35m"
cp .env.ingress.private .env
set -a && source .env && set +a
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


log "dp::hermes::hermes_weagle::(busy)::preparing Weagle (Ingress: Traefik, Grafana, Prometheus) configuration files." 2
origin="./ingress/_docker-compose.yml"
destination="./ingress/docker-compose.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_traefik.yml"
destination="./ingress/traefik.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_dynamic.yml"
destination="./ingress/dynamic.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_prometheus.yml"
destination="./ingress/prometheus.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

origin="./ingress/_alertmanager.yml"
destination="./ingress/alertmanager.yml"
tmpfile=$(mktemp --tmpdir=.)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination


# dir setup
# log "dp::hermes::hermes_weagle::(busy):: Adding .PEM certificates (CA)." 2
# cp ./certs/data/* ./ingress/data/certs
cd $root_dir

take 5 "dp::hermes::hermes_weagle::(busy):: Launching Docker Compose Swarms."
cd ingress

docker compose up -d
cd $root_dir


log "dp::hermes::hermes_weagle::(idle)::all good." 0
