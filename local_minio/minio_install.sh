#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installing"
  cachengo-cli updateInstallStatus $APPID "Installing"
  local HOSTS_ARR
  array_from_json_list HOSTS_ARR "$HOSTNAMES"
  array_len=$((${#HOSTS_ARR[@]}-1 ))
  export MINIO_ACCESS_KEY=$ACCESS_KEY
  export MINIO_SECRET_KEY=$SECRET_KEY

  apt install -y avahi-utils
  apt install -y python3
  apt install -y curl
    
  # install lookup service files
  echo "Installing lookup service files"
  sed -i "s/#hostnames_json#/$HOSTNAMES/" local_minio/minio_lookup.service
  sed -i "s/#group_id#/$GROUPID/" local_minio/minio_lookup.service
  cp local_minio/service_lookup.py /usr/bin/service_lookup.py
  chmod +x /usr/bin/service_lookup.py
  cp local_minio/minio_lookup.service /lib/systemd/system/minio_lookup.service
  chmod 664 /lib/systemd/system/minio_lookup.service
  systemctl daemon-reload
  echo "Service minio_lookup start"
  service minio_lookup start

  platform=`uname -m`
  if [[ $platform == x86_64 ]]; then
    platform=amd64
  fi

  if [[ $platform == aarch64 ]]; then
    platform=arm64
  fi

  
  if [ ! -f /usr/bin/minio ]; then
    echo "Downloading release"
    curl -L -o /usr/bin/minio "http://dl.min.io/server/minio/release/linux-$platform/minio"
    chmod +x /usr/bin/minio
  fi
  sed -i "s/#host_number#/$array_len/" local_minio/minio.service
  sed -i "s/#group_id#/$GROUPID/g" local_minio/minio.service
  cp local_minio/minio.service /lib/systemd/system/minio.service
  chmod 664 /lib/systemd/system/minio.service
  systemctl daemon-reload
  echo "Service minio start"
  service minio start
  echo "Service avahi-daemon restart"
  service avahi-daemon restart
}

function uninstall_only {
  #stop services
  echo "Stoping Services"
  service minio stop
  service minio_lookup stop

  #remove service files
  echo "Removing services files"
  rm /lib/systemd/system/minio.service
  rm /lib/systemd/system/minio_lookup.service
  
  #remove data
  echo "Removing data"
  rm -rfR /data/$GROUPID/
  
  #remove support files
  echo "Removing support files"
  rm /usr/bin/service_lookup.py
  rm /usr/bin/minio
  systemctl daemon-reload
  
  #clean hosts file
  echo "Cleaning host files"
  sed -i "/$GROUPID/d" /etc/hosts
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  uninstall_only
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
