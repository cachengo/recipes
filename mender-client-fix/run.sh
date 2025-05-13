#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing libssl"
  dpkg -i mender-client-fix/libssl1.1_1.1.1f-1ubuntu2.23_arm64.deb
  cachengo-cli updateInstallStatus $APPID "Restarting mender-client"
  systemctl mender-client restart
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "This module cannot be uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
