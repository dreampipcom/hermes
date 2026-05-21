#!/bin/bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

load_env () {
	local private_env=$1
	local public_env=$2
	if [ -f "$private_env" ]; then
		set -a && source "$private_env" && set +a
	else
		set -a && source "$public_env" && set +a
	fi
}

load_env "$root_dir/.env.common.private" "$root_dir/.env.common.public"
load_env "$root_dir/.env.mail.private" "$root_dir/.env.mail.public"

compose_file="$root_dir/mail/docker-compose.yml"

if [ ! -f "$compose_file" ]; then
	echo "missing $compose_file, run $root_dir/init-mail.sh first" >&2
	exit 1
fi

check_tcp () {
	local port=$1
	timeout 5 bash -lc "cat < /dev/null > /dev/tcp/127.0.0.1/$port"
}

cd "$root_dir/mail"

running_services=$(docker compose ps --status running --services)
echo "$running_services" | grep -qx "hermes-mail-stalwart"
echo "$running_services" | grep -qx "hermes-mail-bulwark"

curl -fsS "http://127.0.0.1:${HERMES_PORT_PREFIX}19/admin" > /dev/null
curl -fsS "http://127.0.0.1:${HERMES_PORT_PREFIX}20" > /dev/null

check_tcp "${HERMES_PORT_PREFIX}12"
check_tcp "${HERMES_PORT_PREFIX}13"
check_tcp "${HERMES_PORT_PREFIX}15"
check_tcp "${HERMES_PORT_PREFIX}17"

echo "mail smoke test passed"
