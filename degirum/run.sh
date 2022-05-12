#!/bin/bash
source "utils/parameters.sh"

function do_install {
  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  echo "Installation Successful"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
