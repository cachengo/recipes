#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  docker run \
    --name $APPID \
    -d \
    -p 9000:9000 \
    -e "MINIO_ACCESS_KEY=$ACCESS_KEY" \
    -e "MINIO_SECRET_KEY=$SECRET_KEY" \
    --restart unless-stopped \
    -v /data/minio:/data \
    registry.cachengo.com/cachengo/minio:latest server /data
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  docker stop $APPID
  docker rm $APPID
  rm -rf /data/minio/*
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
