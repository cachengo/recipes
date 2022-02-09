#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  update_status "Installing NextCloud"
  done

snap install nextcloud

nextcloud.enable-https self-signed

update_status "NextCloud Installed"
}

function do_uninstall {
  update_status "Uninstalling Nextcloud"
  rm -rf /data/$GROUPID
  sed -i "/$GROUPID/d" /etc/hosts
  docker stop $APPID
  update_status "Nextcloud Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac