#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  local HOSTS_ARR
  array_from_json_list HOSTS_ARR "$HOSTNAMES"
  array_len=$((${#HOSTS_ARR[@]}-1 ))
  
  # export MINIO_ACCESS_KEY=$ACCESS_KEY
  # export MINIO_SECRET_KEY=$SECRET_KEY

  apt install -y avahi-utils
  apt install -y python3
  apt install -y supervisord
  apt install -y curl 
  
  platform=`uname -m`
  if [[ $platform == x86_64 ]]; then
    dvr_executable=dvr_amd64-linux
  fi

  if [[ $platform == aarch64 ]]; then
    dvr_executable=dvr_arm64-linux
  fi
  
  mkdir /argos 
  chmod a+rwx /argos  #verify correct permissions later
  curl -L -o /argos/dvr "https://downloads.staging.cachengo.com/argos/$dvr_executable"
  chmod +x /argos/dvr

  sed -i "s/#hostnames_json#/$HOSTNAMES/" argos/argos.service
  sed -i "s/#group_id#/$GROUPID/" argos/argos.service
  sed -i "s/#access_key#/$DVR_MINIO_ACCESS_KEY/" argos/argos.service
  sed -i "s/#minio_endpoint#/$DVR_MINIO_ENDPOINT/" argos/argos.service
  sed -i "s/#secret_key#/$DVR_MINIO_SECRET/" argos/argos.service
  sed -i "s/#server_id#/$DVR_SERVER_ID/" argos/argos.service
  sed -i "s/#peer_address#/$DVR_PEER_ADDRESS/" argos/argos.service
  sed -i "s/#join_address#/$DVR_JOIN_ADDRESS/" argos/argos.service
  sed -i "s/#peer_address#/$DVR_PEER_ADDRESS/" argos/argos.service
  sed -i "s/#join_secret#/$DVR_JOIN_SECRET/" argos/argos.service
  sed -i "s/#bootstrap#/$DVR_RAFT_BOOTSTRAP/" argos/argos.service
  sed -i "s/#api_port#/$DVR_API_PORT/" argos/argos.service
  sed -i "s/#leaer_api_port#/$DVR_LEADER_API_PORT/" argos/argos.service
  cp baremetal_minio/service_lookup.py /usr/bin/service_lookup.py
  chmod +x /usr/bin/service_lookup.py
  cp baremetal_minio/minio_lookup.service /lib/systemd/system/minio_lookup.service
  chmod 664 /lib/systemd/system/minio_lookup.service
  systemctl daemon-reload

  

  
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
  service minio start
  service avahi-daemon restart
  echo "Installation Successful"
}

function uninstall_only {
  echo "Stoping Services"
  service argos stop
  
  echo "Removing services files"
  rm /lib/systemd/system/argos.service
  
  
  echo "Removing data"
  rm -rfR /argos
  systemctl daemon-reload
  
  # echo "Cleaning host files"
  # sed -i "/$GROUPID/d" /etc/hosts
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
