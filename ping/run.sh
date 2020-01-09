#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  docker run \
      --net host \
      --name $APPID \
      -d \
      -e REQS_PER_PROCESS=${REQS_PER_SEC:-10} \
      -e PING_RUL=$URL \
      cachengo/pinger:0.0
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  docker stop $APPID
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac