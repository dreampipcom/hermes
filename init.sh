#!/bin/bash
# init.sh
echo -e "\033[0;62m\033[0;49;35m"
set -a && source .env && set +a

# # installing Docker if need be
# if [ "$(which go)" == "" ]; then
# 	echo -e "dp::hermes::(busy)::installing go-lang."
# 	if [ "$(uname)" == "Darwin" ]; then
# 			brew install go@$GOLANG_VERSION    
# 	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
# 			source /etc/os-release && \
# 	    if [[ $ID == "debian" ]]; then \
# 	        sudo add-apt-repository ppa:longsleep/golang-backports
# 					sudo apt update
# 					sudo apt install golang-go
# 	    elif [[ $ID == "alpine" ]]; then \
# 	        apk update && apk add go gcc bash musl-dev openssl-dev ca-certificates && update-ca-certificates
# 					wget https://dl.google.com/go/go$GOLANG_VERSION.src.tar.gz && tar -C /usr/local -xzf go$GOLANG_VERSION.src.tar.gz
# 					cd /usr/local/go/src && ./make.bash
# 					PATH=$PATH:/usr/local/go/bin
# 	    else \
# 	        echo "dp::hermes::(error)::this Linux distribution is not supported yet."; \
# 	        exit 1;
# 	    fi
# 	fi
# else
# 	echo "dp::hermes::(skip)::skipped installing go-lang."
# fi

# # installing any-sync-network
# if [ "$(which any-sync-network)" == "" ]; then
# 	echo "dp::hermes::(busy)::installing any-sync-network.\n"
# 	go install github.com/anyproto/any-sync-tools/any-sync-network@latest
# else
# 	echo "dp::hermes::(skip)::skipped installing any-sync-network."
# fi

# prepare config
echo "dp::hermes::(busy)::preparing Hermes Matrix configuration files."
origin="./matrix/server/_docker-compose.yml"
destination="./matrix/server/docker-compose.yml"
tmpfile=$(mktemp)
cp -p $origin $tmpfile
cat $origin | envsubst > $tmpfile && mv $tmpfile $destination

any-sync-network create

echo -e "\033[0;62m\033[0;49;32m"
echo "dp::hermes::(idle)::all good."
