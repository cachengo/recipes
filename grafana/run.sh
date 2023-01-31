#!/bin/bash

function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"

  kubectl create namespace $APPID

  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-configmap.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-deployment.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-ingress.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-service.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-pvc.yaml

  kubectl apply -f grafana/grafana-configmap.yaml
  kubectl apply -f grafana/grafana-deployment.yaml
  kubectl apply -f grafana/grafana-ingress.yaml
  kubectl apply -f grafana/grafana-service.yaml
  kubectl apply -f grafana/grafana-pvc.yaml

}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  
  kubectl delete -f grafana/grafana-ingress.yaml -n $APPID
  kubectl delete -f grafana/grafana-service.yaml -n $APPID
  kubectl delete -f grafana/grafana-deployment.yaml -n $APPID
  kubectl delete -f grafana/grafana-pvc.yaml -n $APPID
  kubectl delete -f grafana/grafana-configmap.yaml -n $APPID

  kubectl delete namespace $APPID

  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}
case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac