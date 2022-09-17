#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  local HOSTS_ARR
  array_from_json_list HOSTS_ARR "$HOSTNAMES"
  array_len=$((${#HOSTS_ARR[@]}-1 ))
  export MINIO_ACCESS_KEY=$ACCESS_KEY
  export MINIO_SECRET_KEY=$SECRET_KEY

  apt install -y avahi-utils
  apt install -y python3
  apt install -y curl

  touch /etc/dnsmasq.d/$GROUPID.conf

  for ((i=0;i<${#HOSTS_ARR[@]};++i)); do
    echo "cname=${GROUPID}-${i},${HOSTS_ARR[i]}" >> /etc/dnsmasq.d/minio.conf
  done

  systemctl restart dnsmasq

  echo "Installing hostname lookup service" 
  sed -i "s/#hostnames_json#/$HOSTNAMES/" baremetal_minio/minio_lookup.service
  sed -i "s/#group_id#/$GROUPID/" baremetal_minio/minio_lookup.service
  sed -i "s/#hostnames_json#/$HOSTNAMES/" baremetal_minio/restart_avahi.service
  sed -i "s/#group_id#/$GROUPID/" baremetal_minio/restart_avahi.service
  cp baremetal_minio/service_lookup.py /usr/bin/service_lookup.py
  chmod +x /usr/bin/service_lookup.py
  cp baremetal_minio/minio_lookup.service /lib/systemd/system/minio_lookup.service
  cp baremetal_minio/minio_lookup.timer /lib/systemd/system/minio_lookup.timer
  chmod 664 /lib/systemd/system/minio_lookup.service
  chmod 664 /lib/systemd/system/minio_lookup.timer
  systemctl daemon-reload
  systemctl enable minio_lookup.timer

  platform=`uname -m`
  if [[ $platform == x86_64 ]]; then
    platform=amd64
  fi

  if [[ $platform == aarch64 ]]; then
    platform=arm64
  fi

  
  if [ ! -f /usr/bin/minio ]; then
    echo "Downloading Min.io"
    curl -L -o /usr/bin/minio "http://dl.min.io/server/minio/release/linux-$platform/minio"
    chmod +x /usr/bin/minio
  fi
  echo "Installing Min.io service"
  sed -i "s/#access_key#/$ACCESS_KEY/" baremetal_minio/minio.service
  sed -i "s/#secret_key#/$SECRET_KEY/" baremetal_minio/minio.service
  sed -i "s/#host_number#/$array_len/" baremetal_minio/minio.service
  sed -i "s/#group_id#/$GROUPID/g" baremetal_minio/minio.service
  cp baremetal_minio/minio.service /lib/systemd/system/minio.service
  chmod 664 /lib/systemd/system/minio.service
  systemctl daemon-reload
  service avahi-daemon restart
  systemctl start minio_lookup.service
  echo "Installation Successful"
}

function uninstall_only {
  echo "Stopping Services"
  service minio stop
  service minio_lookup stop

  echo "Removing services files"
  rm /lib/systemd/system/minio.service
  rm /lib/systemd/system/minio_lookup.service
  rm /lib/systemd/system/minio_lookup.timer
  
  echo "Removing data"
  rm -rfR /data/$GROUPID/
  
  echo "Removing support files"
  rm /usr/bin/service_lookup.py
  rm /usr/bin/minio
  rm /etc/dnsmasq.d/$GROUPID.conf

  systemctl daemon-reload

  echo "Cleaning host files"
  sed -i "/$GROUPID/d" /etc/hosts
  echo "Uninstallation Successful"
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
