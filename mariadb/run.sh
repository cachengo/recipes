#!/bin/bash

source "utils/cachengo.sh"
source "utils/docker.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"
 
  if [[ -n "$NETWORK" ]]; then
    create_network "$NETWORK"
    NET_FLAG="--network $NETWORK"
  fi

  if [[ $( docker --version ) ]]; then
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
      cachengo-cli updateInstallStatus "$APPID" "Checking service"

    sleep 60
    if [ "$( container_state $APPID)" != "running" ]; then
      NETWORK_NAME=$(get_network)
      delete_network "$NETWORK_NAME"
      exit 1
    fi

  else
    echo "Docker is not installed"
    exit 1 
  fi
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