#!/bin/bash

function do_install {
    cachengo-cli updateInstallStatus $APPID "Installing"
    # zookeeper
    echo "Installing Zookeeper into k3s cluster"
    kubectl create ns zookeeper
    kubectl apply -f argos_k3s/zookeeper/zookeeper.yaml

    # nginx
    echo "Creating nginx ingress"
    ./argos_k3s/nginx/create-nginx.sh

    # minio
    echo "Installing minio"
    kubectl apply -f argos_k3s/minio/minio-namespace.yaml -f argos_k3s/minio/minio-service.yaml -f argos_k3s/minio/minio-pvc.yaml -f argos_k3s/minio/minio-api-ingress.yaml -f minio-console-ingress.yaml -f argos_k3s/minio/minio-deployment.yaml 

    # clickhouse
    ./argos_k3s/clickhouse/create-clickhouse.sh 

    # kubectl -n clickhouse exec chi-pv-log-deployment-pv-0-0-0 -- clickhouse-client --query "create database argos on cluster 'deployment-pv';"

    #argos
    kubectl apply -f argos_k3s/argos/argos-namespace.yaml -f argos_k3s/argos/argos-ingress.yaml -f argos_k3s/argos/argos-pvc.yaml -f argos_k3s/argos/argos-role.yaml -f argos_k3s/argos/argos-service.yaml -f argos_k3s/argos/argos-deployment.yaml

    
    
    cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
    cachengo-cli updateInstallStatus $APPID "Uninstalling"
    kubectl delete -f argos_k3s/zookeeper/zookeeper.yaml 
    kubectl delete ns zookeeper
    kubectl delete -f argos_k3s/minio/minio-deployment.yaml -f argos_k3s/minio/minio-service.yaml -f argos_k3s/minio/minio-pvc.yaml -f argos_k3s/minio/minio-api-ingress.yaml -f minio-console-ingress.yaml -f argos_k3s/minio/minio-namespace.yaml
    kubectl delete -f argos_k3s/clickhouse/clickhouse-deployment.yaml
    kubectl -n clickhouse delete deployment clickhouse-operator
    kubectl -n clickhouse delete svc clickhouse-operator-metrics
    kubectl -n clickhouse delete ns clickhouse
    kubectl delete -f argos_k3s/argos/argos-deployment.yaml -f argos_k3s/argos/argos-ingress.yaml -f argos_k3s/argos/argos-pvc.yaml -f argos_k3s/argos/argos-role.yaml -f argos_k3s/argos/argos-service.yaml -f argos_k3s/argos/argos-namespace.yaml    
    cachengo-cli updateInstallStatus $APPID "Uninstalled"
}

case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
