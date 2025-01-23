#!/bin/bash
source "utils/parameters.sh"

function do_install {
  uninstall_only

  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"

  echo "Upgrading kernel for zfs"

  wget https://downloads.staging.cachengo.com/OS/Venom_v1.2-zfs/linux-headers-5.10.66-1-rockchip-ga3df2c4e4892_5.10.66-1-rockchip_arm64.deb
  wget https://downloads.staging.cachengo.com/OS/Venom_v1.2-zfs/linux-image-5.10.66-1-rockchip-ga3df2c4e4892-dbg_5.10.66-1-rockchip_arm64.deb
  wget https://downloads.staging.cachengo.com/OS/Venom_v1.2-zfs/linux-image-5.10.66-1-rockchip-ga3df2c4e4892_5.10.66-1-rockchip_arm64.deb
  wget https://downloads.staging.cachengo.com/OS/Venom_v1.2-zfs/linux-libc-dev_5.10.66-1-rockchip_arm64.deb

  rm -rf /boot/System*
  rm -rf /boot/config*
  rm -rf /boot/dtbs/*
  rm -rf /boot/initrd*
  rm -rf /vmlinuz*

  dpkg -i ./linux*.deb
  rm -rf ./linux*.deb

  cp /boot/dtbs/5.10.66-1-rockchip-ga3df2c4e4892/rockchip/rk3588-rock-5b.dtb /boot/rk3588-rock-5b.dtb
  cp /boot/vmlinuz* /boot/Image

  apt install -y zfsutils-linux
  
  echo "Updating init file"
  cp zfs_update/init /sbin/init
  chmod +x /sbin/init
  cp zfs_update/cas /sbin/cas
  chmod +x /sbin/cas
  cp zfs_update/cachengo-cas-configurator.service /lib/systemd/system/cachengo-cas-configurator.service
  chmod 664 /lib/systemd/system/cachengo-cas-configurator.service
  systemctl enable cachengo-cas-configurator

  echo "Installation Successful"
}

function uninstall_only {
  echo "Updating init file"
  cp zfs_update/old_init /sbin/init
  chmod +x /sbin/init
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
