#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  wget https://downloads.staging.cachengo.com/cachengo-downloads-staging/llama-cpp-python-0.1.0.tgz
  sudo helm install llama-cpp llama-cpp-python-0.1.0.tgz
  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  sudo helm uninstall llama-cpp
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
