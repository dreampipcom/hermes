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


log "dp::hermes::${HERMES_ENV}::k8s::(busy)::Initiating Kubernetes: ${HERMES_ENV} env."

# install kompose
# Linux
# curl -L https://github.com/kubernetes/kompose/releases/download/v1.34.0/kompose-linux-amd64 -o kompose

# # macOS
# curl -L https://github.com/kubernetes/kompose/releases/download/v1.34.0/kompose-darwin-amd64 -o kompose

# # Windows
# curl -L https://github.com/kubernetes/kompose/releases/download/v1.34.0/kompose-windows-amd64.exe -o kompose.exe

# chmod +x kompose
# sudo mv ./kompose /usr/local/bin/kompose

# prepare
log "dp::hermes::${HERMES_ENV}::k8s::(busy)::Initiating Kubernetes: creating namespaces."
kubectl create namespace hermes

log "dp::hermes::${HERMES_ENV}::k8s::(busy)::Deploying: Weagle (Ingress)." 2
cd ingress
kompose convert
kubectl apply -f *
cd $root_dir

log "dp::hermes::${HERMES_ENV}::k8s::(busy)::Deploying: Drew: (Auth)." 2
cd auth
kompose convert
kubectl apply -f *
cd $root_dir

log "dp::hermes::${HERMES_ENV}::k8s::(busy)::Deploying: Aemilia: (Mail)." 2
cd mail
kompose convert
kubectl apply -f *
cd $root_dir

log "dp::hermes::${HERMES_ENV}::k8s::(busy)::Deploying: Claudia: (Storage, Calendar, MWC)." 2
cd cloud
kompose convert
kubectl apply -f *
cd $root_dir

log "dp::hermes::${HERMES_ENV}::k8s::(idle)::all good." 0