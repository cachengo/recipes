#!/bin/bash

source "utils/cachengo.sh"
source "utils/parameters.sh"

function do_install {
  set -e
  update_status "Installing NextCloud"
  done

snap install nextcloud

nextcloud.enable-https self-signed

update_status "NextCloud Installed"
}