#!/bin/bash
# init weagle
echo -e "\033[0;62m\033[0;49;35m"
cp .env.ingress.local.private .env
set -a && source .env && set +a
set -a && source .env.common.local.private && set +a
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
log "dp::hermes::${HERMES_ENV}::(busy)::Initiating local env."

log "dp::hermes::${HERMES_ENV}::(busy)::Starting: Weagle (Ingress)." 2
./init-weagle.sh

log "dp::hermes::${HERMES_ENV}::(busy)::Starting: Drew: (Auth)." 2
./init-auth.sh

log "dp::hermes::${HERMES_ENV}::(busy)::Starting: Aemilia: (Mail)." 2
./init-mail.sh

log "dp::hermes::${HERMES_ENV}::(busy)::Starting: Claudia: (Storage, Calendar, MWC)." 2
./init-mail.sh

log "dp::hermes::${HERMES_ENV}::(idle)::all good." 0
