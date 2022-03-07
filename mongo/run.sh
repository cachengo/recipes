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
      -e MONGO_INITDB_ROOT_PASSWORD="$ROOT_PASSWORD" \
      -e MONGO_INITDB_ROOT_USERNAME="$ROOT_USERNAME" \
      -e MONGO_INITDB_DATABASE="$DB_NAME" \
      -v "/data/$APPID":/data/db \
      -p "$HOST_PORT":27017 \
      $NET_FLAG \
      mongo:4.4

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