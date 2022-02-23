#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"

  docker run \
    -d --name $APPID \
    -e TZ="America/Puerto_Rico" \
    -e ADVERTISE_IP="http://replace:32400" \
    -v "/data/$APPID/config":/config \
    -v "/data/$APPID/transcode":/transcode \
    -v "/data/$APPID/media":/data \
    -v "$LIBRARY_FOLDER":/library \
    -e PLEX_CLAIM="$PLEX_CLAIM" \
    --network=host \
    cachengo/pms-docker-arm64

  sleep 60
  ADDRESSES=`python plex/fix_preferences.py`
  docker restart $APPID
  cachengo-cli declareSecret -i "$APPID" -n Addresses -v "$ADDRESSES"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  docker stop $APPID
  docker rm $APPID
  rm -rf /data/$APPID
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
