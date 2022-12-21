#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  mkdir -p /data/models
  cp gun_detect/*.py /data/models/
  cp gun_detect/cachengo* /data/models/
  cp gun_detect/logo.txt /data/models/
  cp gun_detect/requirements.txt /data/models/
  if [ ! -f /data/models/yolov5s_relu6_gun-fp32.tflite ]; then
    curl -L -o /data/models/yolov5s_relu6_gun-fp32.tflite "https://downloads.staging.cachengo.com/models/yolov5s_relu6_gun-fp32.tflite"
  fi

  curl -L -o /data/models/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl "https://downloads.staging.cachengo.com/models/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl"
  apt install python3-pip ffmpeg libsm6 libxext6 -y
  python3 -m pip install /data/models/grpcio-1.43.0-cp38-cp38-linux_aarch64.whl
  python3 -m pip install -r /data/models/requirements.txt
  
  echo "Installation Successful"
}

function uninstall_only {

  echo "Removing model"
  rm -rf /data/models/yolov5s_relu6_gun-fp32.tflite
  rm -rf /data/models/detect_gun.py
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
