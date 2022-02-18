#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing Simple Server"
  cd njta/rtsp-simple-server-docker && run.sh -r
  cachengo-cli updateInstallStatus $APPID "Installing RTSP Saver"
  cd njta/rtsp_saver && run.sh -r
  cachengo-cli updateInstallStatus $APPID "Installing S3"
  cd njta/s3_backup && run.sh -r
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  docker stop rtsp_server rtsp_saver s3_backup
  docker rm rtsp_server rtsp_saver s3_backup
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
