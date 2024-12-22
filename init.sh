#!/bin/bash
# init.sh
echo -e "\033[0;62m\033[0;49;35m"
set -a && source .env && set +a
root_dir="$(pwd)"

echo "dp::hermes::(busy)::creating Docker network."
docker network create \
  --driver bridge \
  --subnet=10.10.10.0/24 \
  --gateway=10.10.10.1 \
  --attachable \
  matrix_network

# prepare config
echo "dp::hermes::(busy)::preparing Hermes Matrix Infrastructure configuration files."
origin="./matrix/server/_docker-compose.yml"
destination="./matrix/server/docker-compose.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

echo "dp::hermes::(busy)::preparing Hermes Matrix Home Server configuration files."
origin="./matrix/server/files/_homeserver.yml"
destination="./matrix/server/files/homeserver.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

echo "dp::hermes::(busy)::preparing Hermes Matrix Client configuration files."
origin="./matrix/server/_element-config.json"
destination="./matrix/server/element-config.json"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination
cd $root_dir


echo -e "\033[0;62m\033[0;49;32m"
echo "dp::hermes::(idle)::all good."
