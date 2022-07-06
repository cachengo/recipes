#!/bin/bash

source "utils/cachengo.sh"

DATADIR=/data/$APPID

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  
  cachengo-cli updateInstallStatus $APPID "Installing: Network Stress Test"
  if [ "$SERVER" == "true" ]; then
    NETWORKSERVICE=stress_network_server.service
    cp stress_test/stress_network_server.service /lib/systemd/system/
  else
    NETWORKSERVICE=stress_network_client.service
    sed -i "s/#server_ip#/$SERVER_IP/" stress_test/stress_network_client.service
    cp stress_test/stress_network_client.service /lib/systemd/system/
  fi
  apt install iperf -y

  cachengo-cli updateInstallStatus $APPID "Installing: CPU Stress Test"
  apt install stress -y
  cp stress_test/stress_cpu.service /lib/systemd/system/

  cachengo-cli updateInstallStatus $APPID "Installing: GPU Stress Test"
  apt install hashcat -y
  sed -i "s|#datadir#|$DATADIR|g" stress_test/stress_gpu.service
  cp stress_test/stress_gpu.service /lib/systemd/system/
  mkdir -p $DATADIR
  cd $DATADIR && curl -L https://github.com/hashcat/hashcat/archive/refs/tags/v5.1.0.zip -o hashcat-5.1.0.zip && cd -
  unzip $DATADIR/hashcat-5.1.0.zip -d $DATADIR

  cachengo-cli updateInstallStatus $APPID "Installing: Starting Stress Test"
  systemctl enable $NETWORKSERVICE stress_cpu.service stress_gpu.service
  systemctl daemon-reload
  systemctl start $NETWORKSERVICE stress_cpu.service stress_gpu.service

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  systemctl stop stress_network_*.service stress_cpu.service stress_gpu.service
  rm -rf /lib/systemd/system/stress_network_*.service
  rm -rf /lib/systemd/system/stress_cpu.service
  rm -rf /lib/systemd/system/stress_gpu.service
  rm -rf $DATADIR
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
