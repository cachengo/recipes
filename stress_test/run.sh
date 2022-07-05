#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"

  if [ "$SERVER" == "true" ]; then
    cachengo-cli updateInstallStatus $APPID "Installing: Network Stress Test"
    apt install iperf -y
    cp stress_test/stress_network_server.service /lib/systemd/system/
    cachengo-cli updateInstallStatus $APPID "Installing: CPU Stress Test"
    apt install stress -y
    cp stress_test/stress_cpu.service /lib/systemd/system/
    cachengo-cli updateInstallStatus $APPID "Installing: GPU Stress Test"
    apt install hashcat -y
    cp stress_test/stress_gpu.service /lib/systemd/system/
    cd / && curl -L https://github.com/hashcat/hashcat/archive/refs/tags/v5.1.0.zip -o hashcat-5.1.0.zip && cd -
   # cp stress_test/hashcat-5.1.0.7z /
   # apt install p7zip -y
   # p7zip -d /hashcat-5.1.0.7z
    unzip /hashcat-5.1.0.zip -d /
    cachengo-cli updateInstallStatus $APPID "Installing: Starting Stress Test"
    systemctl enable stress_network_server.service stress_cpu.service stress_gpu.service
    systemctl daemon-reload
    systemctl start stress_network_server.service stress_cpu.service stress_gpu.service
  else
    cachengo-cli updateInstallStatus $APPID "Installing: Network Stress Test"
    apt install iperf -y
    sed -i "s/#server_ip#/$SERVER_IP/" stress_test/stress_network_client.service
    cp stress_test/stress_network_client.service /lib/systemd/system/
    cachengo-cli updateInstallStatus $APPID "Installing: CPU Stress Test"
    apt install stress -y
    cp stress_test/stress_cpu.service /lib/systemd/system/
    cachengo-cli updateInstallStatus $APPID "Installing: GPU Stress Test"
    apt install hashcat -y
    cp stress_test/stress_gpu.service /lib/systemd/system/
    cd / && curl -L https://github.com/hashcat/hashcat/archive/refs/tags/v5.1.0.zip -o hashcat-5.1.0.zip && cd -
   # cp stress_test/hashcat-5.1.0.7z /
   # apt install p7zip -y
   # p7zip -d /hashcat-5.1.0.7z
    unzip /hashcat-5.1.0.zip -d /
    cachengo-cli updateInstallStatus $APPID "Installing: Starting Stress Test"
    systemctl enable stress_network_client.service stress_cpu.service stress_gpu.service
    systemctl daemon-reload
    systemctl start stress_network_client.service stress_cpu.service stress_gpu.service
  fi

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  systemctl stop stress_network_*.service stress_cpu.service stress_gpu.service
  rm -rf /lib/systemd/system/stress_network_*.service
  rm -rf /lib/systemd/system/stress_cpu.service
  rm -rf /lib/systemd/system/stress_gpu.service
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
