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
  log "dp::(idle)::let's wait ($1 * $HERMES_COOLDOWN_POINTER) seconds for $2." 2
  while true; do echo -n .; sleep 1; done | pv -s $1 * $HERMES_COOLDOWN_POINTER  -S -F '%t %p' > /dev/null
}

# docker setup
log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_INGRESS_SUBNET \
  --gateway=$HERMES_INGRESS_GATEWAY \
  --attachable \
  hermes_net_weagle

log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_MODEL_ALL_SUBNET \
  --gateway=$HERMES_MODEL_ALL_GATEWAY \
  --attachable \
  hermes_net_model_all

log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_MODEL_CHAT_SUBNET \
  --gateway=$HERMES_MODEL_CHAT_GATEWAY \
  --attachable \
  hermes_net_model_chat

log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_MODEL_CLOUD_SUBNET \
  --gateway=$HERMES_MODEL_CLOUD_GATEWAY \
  --attachable \
  hermes_net_model_cloud

log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_MODEL_AUTH_SUBNET \
  --gateway=$HERMES_MODEL_AUTH_GATEWAY \
  --attachable \
  hermes_net_model_auth

log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_MAIL_SUBNET \
  --gateway=$HERMES_MAIL_GATEWAY \
  --attachable \
  hermes_net_mail

# docker setup
log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_CLOUD_SUBNET \
  --gateway=$HERMES_CLOUD_GATEWAY \
  --attachable \
  hermes_net_cloud

log "dp::hermes::init::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=$HERMES_CHAT_SUBNET \
  --gateway=$HERMES_CHAT_GATEWAY \
  --attachable \
  hermes_net_chat


# docker setup
log "dp::hermes::${HERMES_ENV}::init::(busy)::Initiating ${HERMES_ENV} env."

log "dp::hermes::${HERMES_ENV}::init::(busy)::Starting: Weagle (Ingress)." 2
./init-weagle.sh

log "dp::hermes::${HERMES_ENV}::init::(busy)::Starting: Daegis (Databases)." 2
./init-model.sh

log "dp::hermes::${HERMES_ENV}::init::(busy)::Starting: Drew: (Auth)." 2
./init-auth.sh

log "dp::hermes::${HERMES_ENV}::init::(busy)::Starting: Aemilia: (Mail)." 2
./init-mail.sh

log "dp::hermes::${HERMES_ENV}::init::(busy)::Starting: Claudia: (Storage, Calendar, MWC)." 2
./init-cloud.sh

log "dp::hermes::${HERMES_ENV}::init::(idle)::all good." 0
