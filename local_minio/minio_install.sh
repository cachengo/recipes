#!/bin/bash
source "utils/parameters.sh"

# IPS_ARR=(

GROUPID=minio-server

function do_install {
  # do_uninstall

  # cachengo-cli updateInstallStatus $APPID "Installing"
  echo "HOSTNAMES is:"
  echo $HOSTNAMES
  local HOSTS_ARR
  array_from_json_list HOSTS_ARR "$HOSTNAMES"
  
  export MINIO_ACCESS_KEY=$ACCESS_KEY
  export MINIO_SECRET_KEY=$SECRET_KEY

  
  apt install -y avahi-utils
  apt install -y python3
  #TODO: call the service_lookup script

  echo "Hosts array is:"
  echo $HOSTS_ARR

  python3 local_minio/service_lookup.py 

  # for ((i=0;i<${#IPS_ARR[@]};++i)); do 
  #   echo "${IPS_ARR[i]} $GROUPID-$i"
  #   echo "${IPS_ARR[i]} $GROUPID-$i" >> /etc/hosts
  # done

  # echo "Total: $i"
  # if [ ! -f /usr/bin/minio ]; then
  #   curl -o /usr/bin/minio https://dl.min.io/server/minio/release/linux-arm64/minio
  #   chmod +x /usr/bin/minio
  # fi
  # cp minio.service /lib/systemd/system/minio.service
  # chmod 664 /lib/systemd/system/minio.service
  # systemctl daemon-reload
  # service minio start
}

function do_uninstall {
  echo "Uninstalling"
  cachengo-cli updateInstallStatus $APPID "Uinstalling"
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
  # rm -rfR /data/*
  # rm  -rfR /data/.*
  # sed -i "/$GROUPID/d" /etc/hosts
  # service minio stop
  # rm /lib/systemd/system/minio.service
  # systemctl daemon-reload
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
