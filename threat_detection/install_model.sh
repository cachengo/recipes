#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  platform=`uname -m`

  mkdir -p /data/threat_detection
  cp threat_detection/*.py /data/threat_detection/
  cp threat_detection/requirements.txt /data/threat_detection/
  cp threat_detection/config.json /data/threat_detection/
  

  sed -i 's/#model#/yolov5n_03-26-23-300.pt/' threat_detection/threat_detection.service
  curl -L -o /data/threat_detection/yolov5n_03-26-23-300.pt "https://downloads.staging.cachengo.com/models/yolov5n_03-26-23-300.pt"
  curl -L -o /data/threat_detection/yolov5n.pt "https://downloads.staging.cachengo.com/models/yolov5n.pt"

  
  cp threat_detection/threat_detection.service /lib/systemd/system/
  cp threat_detection/restart_detection.service /lib/systemd/system/
  cp threat_detection/restart_detection.sh /usr/bin/
  chmod +x /usr/bin/restart_detection.sh
  
  mkdir -p /data/threat_detection/fonts
  cp threat_detection/fonts/Roboto-Medium.ttf /data/threat_detection/fonts/Roboto-Medium.ttf
  
  systemctl daemon-reload

  apt install python3-pip python3.10-venv ffmpeg libsm6 libxext6 -y
  apt install build-essential python3-dev git -y
  python3 -m venv /data/threat_detection/.venv
 
  if [[ $platform == x86_64 ]]; then
    /data/threat_detection/.venv/bin/python3 -m pip install grpcio==1.43.0
  fi

  curl -L -o /data/threat_detection/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl "https://downloads.staging.cachengo.com/models/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl"
  /data/threat_detection/.venv/bin/python -m pip install /data/threat_detection/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl

  /data/threat_detection/.venv/bin/python -m pip install -r /data/threat_detection/requirements.txt
  mkdir -p /data/threat_detection/ultralytics
  git clone https://github.com/ultralytics/yolov5.git /data/threat_detection/ultralytics/yolov5

  echo "Installation Successful"
}

function uninstall_only {

  echo "Removing model"
  rm -rf /data/threat_detection
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
