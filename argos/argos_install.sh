#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  local HOSTS_ARR
  array_from_json_list HOSTS_ARR "$HOSTNAMES"
  array_len=$((${#HOSTS_ARR[@]}-1 ))
  
  apt install -y avahi-utils
  apt install -y python3
  apt install -y supervisor
  apt install -y curl 
  
  platform=`uname -m`
  
  if  [[ $DVR_SERVER_ID == "" ]]; then
    h_name=`hostname`
  else 
    h_name=$DVR_SERVER_ID
  fi 

  peer_addr=$h_name  

  if [[ $platform == x86_64 ]]; then
    dvr_executable=dvr_amd64-linux
    ffmpeg_executable=ffmpeg-amd64-linux
    immudb_executable=immudb-v1.2.4-linux-amd64
  fi

  if [[ $platform == aarch64 ]]; then
    dvr_executable=dvr_arm64-linux
    ffmpeg_executable=ffmpeg-arm64-linux
    immudb_executable=immudb-v1.2.4-linux-arm64
  fi
  
  mkdir /argos 
  mkdir /immudb
  chmod a+rwx /argos  #verify correct permissions later
  chmod a+rwx /immudb 
  curl -L -o /argos/dvr "https://downloads.staging.cachengo.com/argos/$dvr_executable"
  curl -L -o /usr/bin/ffmpeg "https://downloads.staging.cachengo.com/argos/ffmpeg/$ffmpeg_executable"
  curl -L -o /immudb/immudb "https://downloads.staging.cachengo.com/argos/immudb/$immudb_executable"

  chmod a+rwx /argos/dvr
  chmod a+rwx /immudb/immudb 
  chmod a+rwx /usr/bin/ffmpeg

  # Replace vars on lookup service file
  sed -i "s/#hostnames_json#/$HOSTNAMES/" argos/argos_lookup.service
  sed -i "s/#group_id#/$GROUPID/" argos/argos_lookup.service

  # Replace vars on argos service file
  sed -i "s/#access_key#/$DVR_MINIO_ACCESS_KEY/" argos/argos.service
  sed -i "s/#minio_endpoint#/$DVR_MINIO_ENDPOINT/" argos/argos.service
  sed -i "s/#secret_key#/$DVR_MINIO_SECRET/" argos/argos.service
  sed -i "s/#server_id#/$h_name/" argos/argos.service
  sed -i "s/#join_address#/$DVR_JOIN_ADDRESS/" argos/argos.service
  sed -i "s/#peer_address#/$peer_addr/" argos/argos.service
  sed -i "s/#join_secret#/$DVR_JOIN_SECRET/" argos/argos.service
  sed -i "s/#bootstrap#/$DVR_RAFT_BOOTSTRAP/" argos/argos.service
  sed -i "s/#api_port#/$DVR_API_PORT/" argos/argos.service
  sed -i "s/#leader_api_port#/$DVR_LEADER_API_PORT/" argos/argos.service
  
  cp argos/argos.service /lib/systemd/system/argos.service
  cp argos/argos_lookup.service /lib/systemd/system/argos_lookup.service
  cp argos/service_lookup.py /argos/service_lookup.py
  chmod +x /argos/service_lookup.py
  
  systemctl daemon-reload
  service argos start
  service argos_lookup start

  echo "Installation Successful"
}

function uninstall_only {
  echo "Stoping Services"
  service argos stop
  service argos_lookup stop
  
  echo "Removing services files"
  rm /lib/systemd/system/argos.service
  rm /lib/systemd/system/argos_lookup.service
  rm -rf /immudb
  rm /usr/bin/ffmpeg
  rm -rf /argos  
  rm -rf /etc/dvr/
  systemctl daemon-reload
  
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
