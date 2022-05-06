#!/bin/bash

source "utils/cachengo.sh"
source "k3s-follower/install_k3s.sh"

function do_install {
  echo "Running functions"
  if [ -n "$IP_ADDRESS" ]; then
    echo "Setting up k3s URL"
    export K3S_URL="https://$IP_ADDRESS:6443"
  fi 
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
  if [[ -f /var/lib/rancher/k3s/server/node-token ]]; then
    declare_secret k3s_token $( cat /var/lib/rancher/k3s/server/node-token )
  fi    
}

function do_uninstall {
  if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    (exec "/usr/local/bin/k3s-uninstall.sh")
  else
    (exec "/usr/local/bin/k3s-agent-uninstall.sh")
  fi    
}

case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac