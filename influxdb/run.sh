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
      -e DOCKER_INFLUXDB_INIT_MODE=setup \
      -e DOCKER_INFLUXDB_INIT_USERNAME="$ROOT_USERNAME" \
      -e DOCKER_INFLUXDB_INIT_PASSWORD="$ROOT_PASSWORD" \
      -e DOCKER_INFLUXDB_INIT_ORG="$DB_ORG" \
      -e DOCKER_INFLUXDB_INIT_BUCKET="$DB_BUCKET" \
      -e DOCKER_INFLUXDB_INIT_RETENTION="$BUCKET_RETENTION" \
      -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN="$ADMIN_TOKEN" \
      -v "/data/$APPID":/var/lib/influxdb2 \
      -v "/config/$APPID":/etc/influxdb2 \
      -p "$HOST_PORT":8086 \
      $NET_FLAG \
      influxdb:2.0

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