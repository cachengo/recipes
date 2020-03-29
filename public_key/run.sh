#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  # Remove user@host to add our own identifier
  key="$( cut -d ' ' -f 1 <<< "$PUBLIC_KEY" )"
  echo $key $APPID >> /home/$TARGET_USER/.ssh/authorized_keys
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  sed -i "/$APPID/d" /home/*/.ssh/authorized_keys
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
