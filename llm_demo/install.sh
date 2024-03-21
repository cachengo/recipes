#!/bin/bash

source "utils/cachengo.sh"


function do_install {
set -e
cachengo-cli updateInstallStatus $APPID "Installing"


docker run -d \
  --network host \
  --restart unless-stopped \
  --name $APPID \
cachengoci/llm-demo;
  

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