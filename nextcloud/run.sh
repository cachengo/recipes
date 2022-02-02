#!/bin/bash

source "utils/cachengo.sh"
source "utils/parameters.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  done

snap install nextcloud
