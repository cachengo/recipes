#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  local HOSTS_ARR
  array_from_json_list HOSTS_ARR "$HOSTNAMES"
  array_len=$((${#HOSTS_ARR[@]}-1 ))

  # touch /etc/dnsmasq.d/$GROUPID.conf

  # for ((i=0;i<${#HOSTS_ARR[@]};++i)); do
  #   echo "cname=${GROUPID}-${i},${HOSTS_ARR[i]}" >> /etc/dnsmasq.d/$GROUPID.conf
  # done
  touch /etc/cachengo-hosts/$GROUPID.hosts
  chmod u=rwx,g=rwx,o=rwx /etc/cachengo-hosts/$GROUPID.hosts

  for ((i=0;i<${#HOSTS_ARR[@]};++i)); do
    echo "${HOSTS_ARR[i]}    ${GROUPID}-${i}" >> /etc/cachengo-hosts/$GROUPID.hosts
  done

  systemctl restart dnsmasq

  #apt install -y avahi-utils
  #apt install -y python3
  #apt install -y supervisor
  #apt install -y curl
  #apt install -y atomicparsley openjdk-8-jdk

  platform=`uname -m`

#  if  [[ $DVR_SERVER_ID == "" ]]; then
#    h_name=`hostname`
#  else 
#    h_name=$DVR_SERVER_ID
#  fi 

  h_name=$(ifconfig eth0 | grep -v "::" | grep ":" | grep "inet6" | awk '{ print $2 }')

  join_address=""

  for ((i=0;i<${#HOSTS_ARR[@]};++i)); do
    echo "Hosts[i]=${HOSTS_ARR[i]}"
    echo "h name is: $h_name"

    if  [[ ${HOSTS_ARR[i]} == $h_name ]]; then 

      peer_addr="${GROUPID}-${i}"

      if [[ $i != 0 ]] ; then
        echo "Follower node found"
        join_address="${GROUPID}-0:7000"
      fi
    fi
 done



  if [[ $platform == x86_64 ]]; then
    dvr_executable=dvr_amd64-linux
    ffmpeg_executable=ffmpeg-amd64-linux
    immudb_executable=immudb-v1.3.1-linux-amd64
  fi

  if [[ $platform == aarch64 ]]; then
    dvr_executable=dvr_arm64-linux_maria
    ffmpeg_executable=ffmpeg-arm64-linux
    ffprobe_executable=ffprobe-arm64-linux
    immudb_executable=immudb-v1.3.1-linux-arm64
  fi
  
  mkdir /data/argos 
#  mkdir /data/immudb
  chmod a+rwx /data/argos  #verify correct permissions later
 # chmod a+rwx /data/immudb 
  curl -L -o /data/argos/dvr "https://downloads.staging.cachengo.com/argos/$dvr_executable"
  curl -L -o /data/system/usr/bin/ffmpeg "https://downloads.staging.cachengo.com/argos/ffmpeg/$ffmpeg_executable"
  curl -L -o /data/system/usr/bin/ffprobe "https://downloads.staging.cachengo.com/argos/ffmpeg/$ffprobe_executable"
 # curl -L -o /data/immudb/immudb "https://downloads.staging.cachengo.com/argos/immudb/$immudb_executable"
  curl -L -o /etc/CachengoExportConverter.zip "https://downloads.staging.cachengo.com/argos/CachengoExportConverter.zip"
                                               
  unzip /etc/CachengoExportConverter.zip -d /etc/ && rm -rf /etc/CachengoExportConverter.zip 
  # cp argos/dvr_arm64-linux /argos/dvr
  chmod a+rwx /data/argos/dvr
 # chmod a+rwx /data/immudb/immudb 
  chmod a+rwx /usr/bin/ffmpeg
  chmod a+rwx /usr/bin/ffprobe
  # Replace vars on lookup service file
  sed -i "s/#hostnames_json#/$HOSTNAMES/" argos/argos_lookup.service
  # sed -i "s/#group_id#/$GROUPID/" argos/argos_lookup.service

  # Replace vars on argos service file
  sed -i "s/#access_key#/$DVR_MINIO_ACCESS_KEY/" argos/argos.service
  sed -i "s/#minio_endpoint#/$DVR_MINIO_ENDPOINT/" argos/argos.service
  sed -i "s/#secret_key#/$DVR_MINIO_SECRET/" argos/argos.service
  sed -i "s/#server_id#/$h_name/" argos/argos.service
  sed -i "s/#join_address#/$join_address/" argos/argos.service
  sed -i "s/#peer_address#/$peer_addr/" argos/argos.service
  sed -i "s/#join_secret#/$DVR_JOIN_SECRET/" argos/argos.service
  sed -i "s/#api_port#/$DVR_API_PORT/" argos/argos.service
  sed -i "s/#leader_api_port#/$DVR_LEADER_API_PORT/" argos/argos.service
  sed -i "s/#net_interface#/$DVR_NET_INTERFACE/" argos/argos.service
  
  cp argos/argos.service /data/system/system/argos.service
  cp argos/argos_lookup.service /data/system/system/argos_lookup.service
  cp argos/service_lookup.py /data/argos/service_lookup.py
  chmod +x /data/argos/service_lookup.py
  
  systemctl daemon-reload

  service argos_lookup start
  sleep 40
  service argos start
  systemctl enable argos_lookup
  systemctl daemon-reload
  echo "Installation Successful"
}

function uninstall_only {
  echo "Stoping Services"
  service argos stop
  service argos_lookup stop
  
  echo "Removing services files"
  rm /data/system/system/argos.service
  rm /data/system/system/argos_lookup.*
 # rm -rf /data/immudb
 # rm /usr/bin/ffmpeg
 # rm /usr/bin/ffprobe
  rm -rf /data/argos
#  rm -rf /etc/dnsmasq.d/$GROUPID.conf
  rm -rf /data/system/etc/cachengo-hosts/$GROUPID.hosts
  rm -rf /etc/CachengoExportConverter
  systemctl daemon-reload

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
