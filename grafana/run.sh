#!/bin/bash

<<<<<<< Updated upstream
source "utils/cachengo.sh"
source "grafana/grafana-configmap.yaml"
source "grafana/grafana-deployment.yaml"
source "grafana/grafana-ingress.yaml"
source "grafana/grafana-pvc.yaml"
source "grafana/grafana-service.yaml"


=======
>>>>>>> Stashed changes
function do_install {
  set -e
  cachengo-cli updateInstallStatus "$APPID" "Installing"

<<<<<<< Updated upstream
  if [ -n "$NAMESPACE_NAME" ]; then

  kubectl create namespace $NAMESPACE_NAME
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" grafana/grafana-configmap.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" grafana/grafana-deployment.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" grafana/grafana-ingress.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" grafana/grafana-service.yaml
  sed -i "s|#namespace_name#|$NAMESPACE_NAME|g" grafana/grafana-pvc.yaml


  else

  sed -i "s|#namespace_name#|default|g" grafana/grafana-configmap.yaml
  sed -i "s|#namespace_name#|default|g" grafana/grafana-deployment.yaml
  sed -i "s|#namespace_name#|default|g" grafana/grafana-ingress.yaml
  sed -i "s|#namespace_name#|default|g" grafana/grafana-service.yaml
  sed -i "s|#namespace_name#|default|g" grafana/grafana-pvc.yaml


  fi

=======
  kubectl create namespace $APPID

  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-configmap.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-deployment.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-ingress.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-service.yaml
  sed -i "s|#namespace_name#|$APPID|g" grafana/grafana-pvc.yaml
>>>>>>> Stashed changes

  kubectl apply -f grafana/grafana-configmap.yaml
  kubectl apply -f grafana/grafana-deployment.yaml
  kubectl apply -f grafana/grafana-ingress.yaml
  kubectl apply -f grafana/grafana-service.yaml
  kubectl apply -f grafana/grafana-pvc.yaml

}

function do_uninstall {
  cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
  
<<<<<<< Updated upstream
  kubectl delete -f grafana/grafana-configmap.yaml
  kubectl delete -f grafana/grafana-deployment.yaml
  kubectl delete -f grafana/grafana-ingress.yaml
  kubectl delete -f grafana/grafana-service.yaml
  kubectl delete -f grafana/grafana-pvc.yaml
=======
  kubectl delete -f grafana/grafana-ingress.yaml -n $APPID
  kubectl delete -f grafana/grafana-service.yaml -n $APPID
  kubectl delete -f grafana/grafana-deployment.yaml -n $APPID
  kubectl delete -f grafana/grafana-pvc.yaml -n $APPID
  kubectl delete -f grafana/grafana-configmap.yaml -n $APPID

  kubectl delete namespace $APPID
>>>>>>> Stashed changes

  cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}
case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac