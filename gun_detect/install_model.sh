#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  platform=`uname -m`

  mkdir -p /data/models
  cp gun_detect/*.py /data/models/
  cp gun_detect/requirements.txt /data/models/
  cp gun_detect/detections.conf /data/models/
  cp gun_detect/detect_gun.service /lib/systemd/system/
  
  systemctl daemon-reload
  if [ ! -f /data/models/yolov5n_02-02-23_300.pt ]; then
    curl -L -o /data/models/yolov5n_02-02-23_300.pt "https://downloads.staging.cachengo.com/models/yolov5n_02-02-23_300.pt"
  fi

  apt install python3-pip ffmpeg libsm6 libxext6 -y
  apt install build-essential python3-dev -y
 # python3 -m venv /data/models/.venv
 
  if [[ $platform == x86_64 ]]; then
    /data/models/.venv/bin/python3 -m pip install grpcio==1.43.0
  fi

  if [[ $platform == aarch64 ]]; then
    curl -L -o /data/models/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl "https://downloads.staging.cachengo.com/models/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl"
    python3 -m pip install /data/models/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl
  fi

  python3.8 -m pip install -r /data/models/requirements.txt

  echo "Installation Successful"
}

function uninstall_only {

  echo "Removing model"
  rm -rf /data/models/
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
