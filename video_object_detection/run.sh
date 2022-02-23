#!/bin/bash

source "utils/cachengo.sh"

NETNAME=$APPID-net
DBNAME=$APPID-postgres
QUEUENAME=$APPID-redis
SERVERNAME=$APPID-server
WORKERNAME=$APPID-worker
INFERENCENAME=$APPID-inference
DATADIR=/data/$APPID

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  
  mkdir -p $DATADIR
  docker network create -d bridge $NETNAME

  if [ "$INFERENCE_WORKER" == "false" ]; then
    cachengo-cli updateInstallStatus $APPID "Installing: Redis"
    docker run -d \
      --name $QUEUENAME \
      --net=$NETNAME \
      --restart unless-stopped \
      -p 6379:6379 \
      redis:alpine;

    cachengo-cli updateInstallStatus $APPID "Installing: Postgres"
    docker run -d \
        --name $DBNAME \
        --net $NETNAME \
	--restart unless-stopped \
        -p 5432:5432 \
        -e POSTGRES_PASSWORD=password \
        postgres

    cachengo-cli updateInstallStatus $APPID "Installing: Leader Server"
    docker run -d \
      -p 5000:5000 \
      -e CELERY_BROKER_URL=redis://$QUEUENAME:6379 \
      -e CELERY_RESULT_BACKEND=redis://$QUEUENAME:6379 \
      -e CONTAINER_ROLE=server \
      -e DATABASE_URL="postgresql://postgres:password@$DBNAME:5432/postgres" \
      -v $DATADIR:/images \
      --net=$NETNAME \
      --name $SERVERNAME \
      --restart unless-stopped \
      cachengo/video-object-detection:1.0;
    
    cachengo-cli updateInstallStatus $APPID "Installing: Server Worker"
    docker run -d \
      -e CELERY_BROKER_URL=redis://$QUEUENAME:6379 \
      -e CELERY_RESULT_BACKEND=redis://$QUEUENAME:6379 \
      -e CONTAINER_ROLE=server_worker \
      -e DATABASE_URL="postgresql://postgres:password@$DBNAME:5432/postgres" \
      -v $DATADIR:/images \
      --net=$NETNAME \
      --name $WORKERNAME \
      --dns=8.8.8.8 \
      --restart unless-stopped \
      cachengo/video-object-detection:1.0;
  else
    cachengo-cli updateInstallStatus $APPID "Installing: Inference Worker"
    docker run -d \
      --add-host leader:$LEADER_URL \
      --network host \
      --restart unless-stopped \
      -e CELERY_BROKER_URL="redis://leader:6379" \
      -e CELERY_RESULT_BACKEND="redis://leader:6379" \
      -e CONTAINER_ROLE=inference \
      -e LEADER_NODE_URL="http://leader:5000/videos/" \
      -e INFERENCE_MODEL=ssdlite_mobilenet_v2_coco_2018_05_09 \
      -e DATABASE_URL="postgresql://postgres:password@leader:5432/postgres" \
      --name $INFERENCENAME \
      --dns=8.8.8.8 \
    cachengo/video-object-detection:1.0;
  fi

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  docker network rm $NETNAME
  docker stop $APPID-postgres
  docker rm $APPID-postgres
  docker stop $APPID-redis
  docker rm $APPID-redis
  docker stop $APPID-server
  docker rm $APPID-server
  docker stop $APPID-worker
  docker rm $APPID-worker
  docker stop $APPID-inference
  docker rm $APPID-inference
  rm -rf $DATADIR
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
