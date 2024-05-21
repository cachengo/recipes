#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"

  adduser --gecos "$USERNAME" \
          --disabled-password \
          --shell /bin/bash \
    --home /home/$USERNAME \
          "$USERNAME"

  #adduser --home /home/.cachengo cachengo 
  usermod -aG sudo $USERNAME
  #chown -R cachengo:cachengo /home/.cachengo
  mkdir /home/$USERNAME/.ssh
  touch /home/$USERNAME/.ssh/authorized_keys
  chmod 700 /home/$USERNAME/.ssh
  chmod 600 /home/$USERNAME/.ssh/authorized_keys
  chown -R $USERNAME:$USERNAME /home/$USERNAME
  #usermod -aG docker cachengo
  echo "$USERNAME:$USERNAME" | chpasswd

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  deluser --remove-home $USERNAME
  # sed -i "/$APPID/d" /home/*/.ssh/authorized_keys
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
