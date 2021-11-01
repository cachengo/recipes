#!/bin/bash


IPS_ARR=(
    192.168.89.6
    192.168.89.13
    192.168.89.20
    192.168.89.5
    192.168.89.17
    192.168.89.10
    192.168.88.253
    192.168.89.21
    192.168.89.0
    192.168.89.22
    192.168.89.4
    192.168.89.8
    192.168.89.14
    192.168.89.9
    192.168.89.2
    192.168.88.254
    192.168.89.1
    192.168.89.24
    192.168.89.29
    192.168.89.103
    192.168.88.252
    192.168.89.16
    192.168.89.11
    192.168.89.18
    192.168.89.7
    192.168.89.3
    192.168.89.19
    192.168.89.15
    192.168.89.64
    192.168.89.65
    192.168.89.104
    192.168.89.91
)
ACCESS_KEY=access_key
SECRET_KEY=secret_key
GROUPID=minio-server

function do_install {
  do_uninstall

  for ((i=0;i<${#IPS_ARR[@]};++i)); do
    echo "${IPS_ARR[i]} $GROUPID-$i" >> /etc/hosts
  done

  echo "Total: $i"
  if [ ! -f /usr/bin/minio ]; then
    curl -o /usr/bin/minio https://dl.min.io/server/minio/release/linux-arm64/minio
    chmod +x /usr/bin/minio
  fi
  cp minio.service /lib/systemd/system/minio.service
  chmod 664 /lib/systemd/system/minio.service
  systemctl daemon-reload
  service minio start
}

function do_uninstall {
  rm -rfR /data/*
  rm  -rfR /data/.*
  sed -i "/$GROUPID/d" /etc/hosts
  service minio stop
  rm /lib/systemd/system/minio.service
  systemctl daemon-reload
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
