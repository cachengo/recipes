#!/bin/bash

source "utils/cachengo.sh"
source "cube/cube-api-deployment.yaml"
source "cube/cube-api-service.yaml"
source "cube/cube-ingress.yaml"
source "cube/cube-pvc.yaml"
source "cube/redis-configmap.yaml"
source "cube/redis-deployment.yaml"
source "cube/redis-service.yaml"
source "cube/redis-storage.yaml"

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"

  if [ -n "$NAMESPACE_NAME" ]; then

  kubectl create namespace $NAMESPACE_NAME
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/cube-api-deployment.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/cube-api-service.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/cube-ingress.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/cube-pvc.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/redis-configmap.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/redis-deployment.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/redis-service.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" cube/redis-storage.yaml

  else

  sed -i "s|#namespace_name#|default|g" cube/cube-api-deployment.yaml
  sed -i "s|#namespace_name#|default|g" cube/cube-api-service.yaml
  sed -i "s|#namespace_name#|default|g" cube/cube-ingress.yaml
  sed -i "s|#namespace_name#|default|g" cube/cube-pvc.yaml
  sed -i "s|#namespace_name#|default|g" cube/redis-configmap.yaml
  sed -i "s|#namespace_name#|default|g" cube/redis-deployment.yaml
  sed -i "s|#namespace_name#|default|g" cube/redis-service.yaml
  sed -i "s|#namespace_name#|default|g" cube/redis-storage.yaml

  fi

  kubectl apply -f cube/cube-api-deployment.yaml
  kubectl apply -f cube/cube-api-service.yaml
  kubectl apply -f cube/cube-ingress.yaml
  kubectl apply -f cube/cube-pvc.yaml
  kubectl apply -f cube/redis-configmap.yaml
  kubectl apply -f cube/redis-deployment.yaml
  kubectl apply -f cube/redis-service.yaml
  kubectl apply -f cube/redis-storage.yaml

}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  
  kubectl delete -f cube/cube-api-deployment.yaml
  kubectl delete -f cube/cube-api-service.yaml
  kubectl delete -f cube/cube-ingress.yaml
  kubectl delete -f cube/cube-pvc.yaml
  kubectl delete -f cube/redis-configmap.yaml
  kubectl delete -f cube/redis-deployment.yaml
  kubectl delete -f cube/redis-service.yaml
  kubectl delete -f cube/redis-storage.yaml

  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}
case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac