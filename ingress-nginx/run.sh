#!/bin/bash

source "utils/cachengo.sh"
source "utils/kubernetes.sh"

function do_install {
  set -e
  cachengo-cli updateInstallStatus $APPID "Installing"
  
  if [[ $( which helm ) >/dev/null ]]; then
  
  echo "Helm is installed..."

  else

  echo "Installing Helm..."
  curl -O https://get.helm.sh/helm-v3.10.2-linux-arm.tar.gz
  tar -zxvf helm-v3.10.2-linux-arm.tar.gz
  mv linux-arm/helm /usr/local/bin/helm

  fi

  KUBE_PATH=$(get_kubeconfig_path)

  helm upgrade ingress-nginx ingress-nginx \
  --install --repo https:// kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.hostNetwork=true \
  --set controller.dnsPolicy=ClusterFirstWithHostNet \
  --set controller.kind=DaemonSet --kubeconfig $KUBE_PATH

}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"

  KUBE_PATH=$(get_kubeconfig_path)

  helm uninstall ingress-nginx --namespace ingress-nginx --kubeconfig $KUBE_PATH

  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
