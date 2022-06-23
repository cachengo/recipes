#!/bin/bash

source "utils/cachengo.sh"
source "utils/docker.sh"
source "utils/parameters.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"
  
  mkdir /data/$APPID

  local MASTER_ARR
  array_from_json_list MASTER_ARR "$MASTER_NODES"
  array_len=$((${#MASTER_ARR[@]}-1 ))

  MASTER_STRING=""
  for ((i=0;i<${#MASTER_ARR[@]};++i)); do 
    MASTER_STRING="$MASTER_STRING${MASTER_ARR[i]}:$MASTER_PORT,"
  done
  MASTER_STRING=${MASTER_STRING::-1}
    
  if [[ $( docker --version ) ]]; then
    docker run \
      -d \
      --name "$APPID" \
      --net=host \
      -v /data/$APPID:/data \
      chrislusf/seaweedfs server \
        -master.port=$MASTER_PORT -dir="/data" -volume.port=$VOLUME_PORT \
        -ip.bind=0.0.0.0 -master.peers=$MASTER_STRING

    sleep 60
    if [ "$( container_state $APPID)" != "running" ]; then
      exit 1
    fi

  else
    echo "Docker is not installed"
    exit 1 
  fi
  
}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  docker stop "$APPID"
  docker rm "$APPID"
  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}

case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac