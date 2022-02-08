#!/bin/bash

source "utils/cachengo.sh"

function create_network {
  docker network inspect "$1" >/dev/null 2>&1 || \
  docker network create --driver bridge "$1"
}

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"
 
  if [[ -n "$NETWORK" ]]; then
    create_network "$NETWORK"
    NET_FLAG="--network $NETWORK"
  fi

  docker run \
    -d \
    --name "$APPID" \
    -e MARIADB_USER="$DB_USER" \
    -e MARIADB_PASSWORD="$DB_PASSWORD" \
    -e MARIADB_DATABASE="$DATABASE_NAME" \
    -e MARIADB_ROOT_PASSWORD="$ROOT_PASSWORD" \
    -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD="$ALLOW_EMPTY_ROOT_PASSWORD" \
    -e MARIADB_RANDOM_ROOT_PASSWORD="$RANDOM_ROOT_PASSWORD" \
    -v "/data/$APPID":/var/lib/mysql \
    -p "$HOST_PORT":3306 \
    $NET_FLAG \
    mariadb:10.7
  cachengo-cli updateInstallStatus "$APPID" "Installed"
}

function delete_network {    
  if [ $( docker network inspect "$1" | grep '"Containers": {},' | wc -l ) -gt 0 ]; then
    docker network rm "$1"
  fi  
}

function get_network { 
  NETWORK_NAME=$(docker inspect "$APPID" | jq '.[0].NetworkSettings.Networks' | jq 'keys[0]' | cut -d '"' -f 2)
  echo "$NETWORK_NAME"
}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  NETWORK_NAME=$(get_network)
  docker stop "$APPID"
  docker rm "$APPID"
  delete_network "$NETWORK_NAME"
  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}

case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac