#!/bin/bash

source "utils/cachengo.sh"
source "postgres-on-kubernetes/postgres-secret.yaml"
source "postgres-on-kubernetes/postgres-service.yaml"
source "postgres-on-kubernetes/postgres-configmap.yaml"
source "postgres-on-kubernetes/postgres-storage.yaml"
source "postgres-on-kubernetes/postgres-statefulset.yaml"

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"

  if [ -n "$NAMESPACE_NAME" ]; then

  kubectl create namespace $NAMESPACE_NAME
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" postgres-on-kubernetes/postgres-configmap.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" postgres-on-kubernetes/postgres-secret.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" postgres-on-kubernetes/postgres-service.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" postgres-on-kubernetes/postgres-statefulset.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" postgres-on-kubernetes/postgres-storage.yaml
  
  else

  sed -i "s|#namespace_name#|default|g" postgres-on-kubernetes/postgres-configmap.yaml
  sed -i "s|#namespace_name#|default|g" postgres-on-kubernetes/postgres-secret.yaml
  sed -i "s|#namespace_name#|default|g" postgres-on-kubernetes/postgres-service.yaml
  sed -i "s|#namespace_name#|default|g" postgres-on-kubernetes/postgres-statefulset.yaml
  sed -i "s|#namespace_name#|default|g" postgres-on-kubernetes/postgres-storage.yaml

  fi

  sed -i "s|#postgres_user#|$POSTGRES_USER|g" postgres-on-kubernetes/postgres-secret.yaml
  sed -i "s|#postgres_password#|$POSTGRES_PASSWORD|g" postgres-on-kubernetes/postgres-secret.yaml
  kubectl apply -f postgres-on-kubernetes/postgres-secret.yaml
  
  kubectl apply -f postgres-on-kubernetes/postgres-service.yaml
  kubectl apply -f postgres-on-kubernetes/postgres-statefulset.yaml
  kubectl apply -f postgres-on-kubernetes/postgres-configmap.yaml
  kubectl apply -f postgres-on-kubernetes/postgres-storage.yaml

}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  
  kubectl delete -f postgres-on-kubernetes/postgres-service.yaml
  kubectl delete -f postgres-on-kubernetes/postgres-secret.yaml  
  kubectl delete -f postgres-on-kubernetes/postgres-statefulset.yaml
  kubectl delete -f postgres-on-kubernetes/postgres-configmap.yaml
  kubectl delete -f postgres-on-kubernetes/postgres-storage.yaml

  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}
case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac