#!/bin/bash

source "utils/cachengo.sh"
source "utils/parameters.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  local IPS_ARR
  array_from_json_list IPS_ARR "$IPS"
  export MINIO_ACCESS_KEY=$ACCESS_KEY
  export MINIO_SECRET_KEY=$SECRET_KEY
  mkdir /data/dist_minio
  #count number of nodes
  #write to hosts file
  minio server http://host{1...32}/data/dist_minio
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  rm -rf /data/dist_minio
  #clean host file
  docker stop $APPID
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
