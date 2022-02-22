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
      -e POSTGRES_PASSWORD="$DB_PASSWORD" \
      -e POSTGRES_USER="$DB_USER" \
      -e POSTGRES_DB="$DB_NAME" \
      -e POSTGRES_INITDB_ARGS="$DB_ARGS" \
      -v "/data/$APPID":/var/lib/postgresql/data \
      -p "$HOST_PORT":5432 \
      $NET_FLAG \
      postgres:14.2
    cachengo-cli updateInstallStatus "$APPID" "Installed"
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