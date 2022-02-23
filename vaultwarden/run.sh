#!/bin/bash

source "utils/cachengo.sh"
export IMAGE="vaultwarden/server:latest"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing VaultWarden"
  docker pull vaultwarden/server:latest 
  docker run -d --name vaultwarden -v /data/vw-data/:/data/ -e ADMIN_TOKEN=$ADMIN_TOKEN -p 80:80 vaultwarden/server:latest 
  cachengo-cli updateInstallStatus $APPID "Installed Vaultwarden"
}
function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling Vaultwarden"
  rm -rf /data/$GROUPID
  sed -i "/$GROUPID/d" /etc/hosts
  docker stop $APPID
  docker rm $APPID 
  docker rmi $IMAGE
  rm -rf /data/vw-data/ 
  docker exec -it vaultwarden export ADMIN_TOKEN=
  cachengo-cli updateInstallStatus $APPID "Uninstalled VaultWarden"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
