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
  mkdir -p /data/minio

  if [ -d '/data/system/etc/cachengo-hosts' ]; then
 #   touch /etc/dnsmasq.d/$GROUPID.conf

  #  for ((i=0;i<${#HOSTS_ARR[@]};++i)); do
  #    echo "cname=${GROUPID}-${i},${HOSTS_ARR[i]}" >> /etc/dnsmasq.d/$GROUPID.conf
  #  done
    touch /etc/cachengo-hosts/$GROUPID.hosts
    chmod u=rwx,g=rwx,o=rwx /etc/cachengo-hosts/$GROUPID.hosts

    for ((i=0;i<${#HOSTS_ARR[@]};++i)); do
      echo "${HOSTS_ARR[i]}    ${GROUPID}-${i}" >> /etc/cachengo-hosts/$GROUPID.hosts
    done

    systemctl restart dnsmasq
   # cp baremetal_minio/minio_lookup_dnsmasq.py /data/minio/minio_lookup.py
   # chmod +x /data/minio/minio_lookup.py
   # cp baremetal_minio/restart_avahi.py /data/minio/restart_avahi.py
   # chmod +x /data/minio/restart_avahi.py
   # cp baremetal_minio/restart_avahi.service /lib/systemd/system/restart_avahi.service
   # chmod 664 /lib/systemd/system/restart_avahi.service
   # systemctl enable restart_avahi
   # systemctl daemon-reload
   # service avahi-daemon restart
   # systemctl start restart_avahi.service

  else
    for ((i=0;i<${#HOSTS_ARR[@]};++i)); do
      echo "${HOSTS_ARR[i]}    ${GROUPID}-${i}" >> /etc/hosts
    done
   # cp baremetal_minio/minio_lookup.py /data/minio/minio_lookup.py
   # cp baremetal_minio/restart_avahi.py /data/minio/restart_avahi.py
   # chmod +x /data/minio/minio_lookup.py
   # chmod +x /data/minio/restart_avahi.py
   # cp baremetal_minio/restart_avahi.service /lib/systemd/system/restart_avahi.service
   # chmod 664 /lib/systemd/system/restart_avahi.service
   # systemctl enable restart_avahi
   # systemctl daemon-reload
   # service avahi-daemon restart
   # systemctl start restart_avahi.service
  fi

 # echo "Installing hostname lookup service"
 # sed -i "s/#hostnames_json#/$HOSTNAMES/" baremetal_minio/minio_lookup.service
 # sed -i "s/#group_id#/$GROUPID/" baremetal_minio/minio_lookup.service
 # cp baremetal_minio/minio_lookup.service /lib/systemd/system/minio_lookup.service
 # chmod 664 /lib/systemd/system/minio_lookup.service
 # systemctl daemon-reload
 # systemctl enable minio_lookup

  platform=`uname -m`
  if [[ $platform == x86_64 ]]; then
    platform=amd64
  fi

  if [[ $platform == aarch64 ]]; then
    platform=arm64
  fi


  if [ ! -f /data/minio/minio ]; then
    echo "Downloading Min.io"
    curl -L -o /data/minio/minio "http://dl.min.io/server/minio/release/linux-$platform/minio"
    chmod +x /data/minio/minio
  fi

  echo "Installing Min.io service"
  sed -i "s/#access_key#/$ACCESS_KEY/" baremetal_minio/minio.service
  sed -i "s/#secret_key#/$SECRET_KEY/" baremetal_minio/minio.service
  sed -i "s/#host_number#/$array_len/" baremetal_minio/minio.service
  sed -i "s/#group_id#/$GROUPID/g" baremetal_minio/minio.service
  if [ -d '/data/system/system' ]; then
    cp baremetal_minio/minio.service /data/system/system/minio.service
    chmod 664 /data/system/system/minio.service
  else
    cp baremetal_minio/minio.service /lib/systemd/system/minio.service
    chmod 664 /lib/systemd/system/minio.service 
  fi
  #cp baremetal_minio/minio.service /data/system/system/minio.service
  #chmod 664 /lib/systemd/system/minio.service
  systemctl daemon-reload
  systemctl enable minio
  #systemctl start minio_lookup.service
  systemctl start minio
  echo "Installation Successful"
}

function uninstall_only {
  echo "Stopping Services"
  systemctl stop minio
  #service minio_lookup stop

  echo "Removing services files"
  if [ -d '/data/system/system' ]; then
    rm -rf /data/system/system/minio.service
  else
    rm -rf /lib/systemd/system/minio.service 
  fi

#  rm /lib/systemd/system/minio.service
#  rm /lib/systemd/system/minio_lookup.service
  
  echo "Removing data"
  rm -rfR /data/minio

  echo "Removing support files"
#  rm /data/minio/minio_lookup.py
#  rm /data/minio/minio
 # if [ "$DNSMASQ" == "true" ]; then
  if [ -d '/data/system/etc/cachengo-hosts' ]; then 
    rm /data/system/etc/cachengo-hosts/$GROUPID.hosts
  else
 #   rm /lib/systemd/system/restart_avahi.service
 #   echo "Cleaning host files"
    sed -i "/$GROUPID/d" /etc/hosts
  fi

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
