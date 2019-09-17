#!/bin/bash

source "utils/cachengo.sh"
source "utils/parameters.sh"

function do_install {
  update_status "Installing"
  local PORTS_ARR
  local ENVVARS_ARR
  array_from_json_list PORTS_ARR "$PORTS"
  array_from_json_list ENVVARS_ARR "$ENVVARS"
  declare -p PORTS_ARR
  docker run -d "${PORTS_ARR[@]/#/-p}" "${ENVVARS_ARR[@]/#/-e}" -n $APPID $IMAGE
  update_status "Installed"
}

function do_uninstall {
  update_status "Uninstalling"
  docker stop $APPID
  docker rm $APPID
  update_status "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
