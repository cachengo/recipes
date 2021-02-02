#!/bin/bash

source "utils/cachengo.sh"

NETNAME=$APPID-net
DATADIR=/data/$APPID

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  
  mkdir -p $DATADIR
  docker network create -d bridge $NETNAME

  cachengo-cli updateInstallStatus $APPID "Installing: Search"
  docker run -d \
    -v $DATADIR/index256:/db \
    -e "ANN_INDEX_LENGTH=256" \
    --network=$NETNAME \
    --name $APPID-nn_search \
    registry.cachengo.com/cachengo/nn_search:2.0

  cachengo-cli updateInstallStatus $APPID "Installing: Facerec"
  docker run -d \
    --network=$NETNAME \
    --name=$APPID-facerec \
    registry.cachengo.com/cachengo/facerec:1.0

  cachengo-cli updateInstallStatus $APPID "Installing: Server"
  docker run -d \
    -p 5001:5000 \
    -v $DATADIR/sso:/db \
    -e "NN_SEARCH_ADDRESS=$APPID-nn_search:1323" \
    -e "FACEREC_ADDRESS=$APPID-facerec:5000" \
    --network=$NETNAME \
    --name $APPID-sso \
    registry.cachengo.com/cachengo/sso_example:1.5

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  docker network rm $NETNAME
  docker stop $APPID-nn_search
  docker rm $APPID-nn_search
  docker stop $APPID-facerec
  docker rm $APPID-facerec
  docker stop $APPID-sso
  docker rm $APPID-sso
  rm -rf $DATADIR
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
