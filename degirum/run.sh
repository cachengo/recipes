#!/bin/bash
source "utils/parameters.sh"

function do_install {
  echo "Installation started"
  cachengo-cli updateInstallStatus $APPID "Installing"
  mkdir /data/zoo
  python3 -m pip install degirum --extra-index-url https://degirum.github.io/simple
  cd /data/zoo/
  python3 -c "from degirum import server; server.download_models('.')"
  cp degirum/degirum_server.service /lib/systemd/system/
  systemctl enable degirum_server.service
  systemctl daemon-reload
  systemctl start degirum_server.service
  echo "Installation Successful"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  python3 -m pip uninstall degirum
  rm -rf /lib/systemd/system/degirum_server.service
  rm -rf /data/zoo
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
