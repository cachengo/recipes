#!/bin/bash
source "utils/parameters.sh"

# IPS_ARR=(

GROUPID=minio-server

function do_install {
  # do_uninstall

  # cachengo-cli updateInstallStatus $APPID "Installing"
  local HOSTS_ARR
  array_from_json_list HOSTS_ARR "$HOSTNAMES"
  
  export MINIO_ACCESS_KEY=$ACCESS_KEY
  export MINIO_SECRET_KEY=$SECRET_KEY

  apt install -y avahi-utils
  apt install -y python3
  

  #output hostnames to use with lookup service to a common file
  echo $HOSTNAMES > /usr/bin/minio_lookup_hostnames.json
    
  # install lookup service files  
  cp minio_lookup.service /lib/systemd/system/minio_lookup.service
  chmod 664 /lib/systemd/system/minio_lookup.service
  systemctl daemon-reload
  service minio_lookup start

  
  if [ ! -f /usr/bin/minio ]; then
    curl -o /usr/bin/minio https://dl.min.io/server/minio/release/linux-x86/minio
    chmod +x /usr/bin/minio
  fi
  cp minio.service /lib/systemd/system/minio.service
  chmod 664 /lib/systemd/system/minio.service
  systemctl daemon-reload
  service minio start
}

function do_uninstall {
  echo "Uninstalling"
  cachengo-cli updateInstallStatus $APPID "Uinstalling"
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
  rm -rfR /data/*
  rm  -rfR /data/.*
  sed -i "/$GROUPID/d" /etc/hosts
  service minio stop
  rm /lib/systemd/system/minio.service
  service minio_lookup stop
  rm /lib/systemd/system/minio_lookup.service
  rm /usr/bin/service_lookup.py
  rm /usr/bin/minio_lookup_hostnames.json
  systemctl daemon-reload
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
