#!/bin/bash
source "utils/parameters.sh"

function do_install {
  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"

  docker run -d \
    --name $APPID \
    -p 8778:8778 \
    --restart unless-stopped \
    cachengo/degirum-server:1.0;

  cachengo-cli updateInstallStatus $APPID "Installed"
  echo "Installation Successful"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
    docker stop $APPID
    docker rm $APPID
    docker image rm degirum-server:1.0
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
