#!/bin/bash

source "utils/cachengo.sh"
source "utils/parameters.sh"
source "rancher.sh"

function do_install {
    verify_system
    setup_env "$@"
    download_and_verify
    setup_selinux
    create_symlinks
    create_killall
    create_uninstall
    systemd_disable
    create_env_file
    create_service_file
    service_enable_and_start
    if [-z "$IP_ADDRESS"] then
      K3S_TOKEN=$K3S_TOKEN k3s server --cluster-init
    else 
      K3S_TOKEN=$K3S_TOKEN k3s server --server https://$IP_ADDRESS:6443
    fi
}

function do_uninstall {
  source "/usr/local/bin/k3s-uninstall.sh"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac