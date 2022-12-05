#!/bin/bash

source "utils/cachengo.sh"
source "jitsu/jitsu-configmap.yaml"
source "jitsu/jitsu-service.yaml"
source "jitsu/jitsu-deployment.yaml"
source "jitsu/jitsu-ingress.yaml"
source "jitsu/redis-configmap.yaml"
source "jitsu/redis-deployment.yaml"
source "jitsu/redis-service.yaml"
source "jitsu/redis-storage.yaml"

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"

  if [ -n "$NAMESPACE_NAME" ]; then

  kubectl create namespace $NAMESPACE_NAME
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/jitsu-configmap.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/jitsu-service.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/jitsu-deployment.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/jitsu-ingress.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/redis-configmap.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/redis-deployment.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/redis-service.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" jitsu/redis-storage.yaml

  else

  sed -i "s|#namespace_name#|default|g" jitsu/jitsu-configmap.yaml
  sed -i "s|#namespace_name#|default|g" jitsu/jitsu-service.yaml
  sed -i "s|#namespace_name#|default|g" jitsu/jitsu-deployment.yaml
  sed -i "s|#namespace_name#|default|g" jitsu/jitsu-ingress.yaml
  sed -i "s|#namespace_name#|default|g" jitsu/redis-configmap.yaml
  sed -i "s|#namespace_name#|default|g" jitsu/redis-deployment.yaml
  sed -i "s|#namespace_name#|default|g" jitsu/redis-service.yaml
  sed -i "s|#namespace_name#|default|g" jitsu/redis-storage.yaml

  fi

  kubectl apply -f jitsu/jitsu-configmap.yaml
  kubectl apply -f jitsu/jitsu-service.yaml
  kubectl apply -f jitsu/jitsu-deployment.yaml
  kubectl apply -f jitsu/jitsu-ingress.yaml
  kubectl apply -f jitsu/redis-configmap.yaml
  kubectl apply -f jitsu/redis-deployment.yaml
  kubectl apply -f jitsu/redis-service.yaml
  kubectl apply -f jitsu/redis-storage.yaml

}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  
  kubectl delete -f jitsu/jitsu-configmap.yaml
  kubectl delete -f jitsu/jitsu-service.yaml
  kubectl delete -f jitsu/jitsu-deployment.yaml
  kubectl delete -f jitsu/jitsu-ingress.yaml
  kubectl delete -f jitsu/redis-configmap.yaml
  kubectl delete -f jitsu/redis-deployment.yaml
  kubectl delete -f jitsu/redis-service.yaml
  kubectl delete -f jitsu/redis-storage.yaml

  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}
case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac