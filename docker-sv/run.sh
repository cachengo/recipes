#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  mkdir -p /bitcoin-data
  docker run \
    --name $APPID \
    -d \
    -p 8332:8332 \
    -p 8333:8333 \
    -p 9332:9332 \
    -p 9333:9333 \
    -p 18332:18332 \
    -p 18333:18333 \
    -v ~/bitcoin-data:/data \
    --restart unless-stopped \
    registry.cachengo.com/cachengo/docker-sv-aarch64:0.0
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  docker stop $APPID
  docker rm $APPID
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
