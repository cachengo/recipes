#!/bin/bash

source "utils/cachengo.sh"
source "utils/parameters.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  echo $IPS
  local IPS_ARR
  array_from_json_list IPS_ARR "$IPS"
  export MINIO_ACCESS_KEY=$ACCESS_KEY
  export MINIO_SECRET_KEY=$SECRET_KEY

  for ((i=0;i<${#IPS_ARR[@]};++i)); do 
    echo "${IPS_ARR[i]} $GROUPID-$i"
    echo "${IPS_ARR[i]} $GROUPID-$i" >> /etc/hosts
  done

  echo "Total: $i"

  docker run -p 9000:9000 \
    --name $APPID \
    -d \
    -e "MINIO_ROOT_USER=$ACCESS_KEY" \
    -e "MINIO_ROOT_PASSWORD=$SECRET_KEY" \
    --net host \
    --restart unless-stopped \
    registry.cachengo.com/minio/minio server http://$GROUPID-{0...$((i-1))}/data/

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  rm -rf /data/dist_minio
  sed -i "/$GROUPID/d" /etc/hosts
  docker stop $APPID
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
