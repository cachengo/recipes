#!/bin/bash

source "utils/cachengo.sh"
source "longhorn/longhorn-service.yaml"
source "longhorn/longhorn.yaml"
source "longhorn/uninstall.yaml"

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"
  
  apt update -y
  apt-get install open-iscsi -y
  apt-get install jq -y
  apt install -y nfs-common

  if [ "$( kubectl config view | grep "clusters:")" != "clusters: null" ]; then
  if [ "$( kubectl get namespace --output json -o jsonpath='{.items[?(@.metadata.name=="longhorn-system")].metadata.name}')" != "longhorn-system" ]; then
  sleep 60
  sed -i "s|#default_data#|/data/$GROUPID|g" longhorn/longhorn.yaml
  kubectl apply -f longhorn/longhorn.yaml
  cat > longhorn-service.yaml
  cp -f longhorn/longhorn-service.yaml longhorn-service.yaml
  echo "Starting longhorn service..."
  kubectl apply -f longhorn-service.yaml -n longhorn-system
  fi
  fi
}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  if [ "$( kubectl config view | grep "clusters:")" != "clusters: null" ]; then
  if [ "$( kubectl get namespace --output json -o jsonpath='{.items[?(@.metadata.name=="longhorn-system")].metadata.name}')" == "longhorn-system" ]; then
  kubectl create -f longhorn/uninstall.yaml
  sleep 60
  kubectl delete -f longhorn/longhorn.yaml
  kubectl delete -f longhorn/uninstall.yaml
  fi
  fi
  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}
case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac