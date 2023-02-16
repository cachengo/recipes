#!/bin/bash

source "utils/cachengo.sh"
source "utils/service.sh"
source "k3s-leader/install_k3s.sh"

function do_install {
  echo "K3S EXEC"
  if [ -n "$IP_ADDRESS" ]; then
    if [ -z "$SECRET" ]; then
      echo "SECRET must not be empty when IP ADDRESS is set...Exiting"
      exit 1
    fi 
    export K3S_TOKEN="$SECRET"
    export INSTALL_K3S_EXEC="server --server https://$IP_ADDRESS:6443 --disable traefik --disable servicelb \
    --kubelet-arg "node-status-update-frequency=4s" \
    --kube-controller-manager-arg "node-monitor-period=4s" \
    --kube-controller-manager-arg "node-monitor-grace-period=16s" \
    --kube-controller-manager-arg "pod-eviction-timeout=20s" \
    --kube-apiserver-arg "default-not-ready-toleration-seconds=20" \
    --kube-apiserver-arg "default-unreachable-toleration-seconds=20""
  else
    export K3S_TOKEN="$SECRET"
    export INSTALL_K3S_EXEC="server --cluster-init --disable traefik --disable servicelb \
    --kubelet-arg "node-status-update-frequency=4s" \
    --kube-controller-manager-arg "node-monitor-period=4s" \
    --kube-controller-manager-arg "node-monitor-grace-period=16s" \
    --kube-controller-manager-arg "pod-eviction-timeout=20s" \
    --kube-apiserver-arg "default-not-ready-toleration-seconds=20" \
    --kube-apiserver-arg "default-unreachable-toleration-seconds=20""
  fi 
    export K3S_KUBECONFIG_MODE="644"
    eval set -- $(escape "${INSTALL_K3S_EXEC}") $(quote "$@")
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
    wait_for_service_active "k3s.service" 40
  if [[ -f /var/lib/rancher/k3s/server/node-token ]]; then
    declare_secret k3s_token $( cat /var/lib/rancher/k3s/server/node-token )
  fi
}

function do_uninstall {
  if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    (exec "/usr/local/bin/k3s-uninstall.sh")
  else
    echo "Uninstall script not found...Exiting"
    exit 1
  fi    
}

case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac