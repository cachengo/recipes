#!/bin/bash

function do_install {
    # zookeeper
    echo "Installing Zookeeper into k3s cluster"
    kubectl create ns zookeeper
    kubectl apply -f zookeeper/zookeeper.yaml

    # nginx
    echo "Creating nginx ingress"
    ./nginx/create-nginx.sh

    # minio
    echo "Installing minio"
    kubectl apply -f minio/minio-namespace.yaml -f minio/minio-service.yaml -f minio/minio-pvc.yaml -f minio/minio-ingress.yaml -f minio/minio-deployment.yaml 

    # clickhouse
    ./clickhouse/create-clickhouse.sh 

    sleep 60

    kubectl -n clickhouse exec chi-pv-log-deployment-pv-0-0-0 -- clickhouse-client --query "create database argos on cluster 'deployment-pv';"

    #argos
    kubectl apply -f argos-namespace.yaml -f argos-ingress.yaml -f argos-pvc.yaml -f argos-role.yaml -f argos-service.yaml -f argos-deployment.yaml

}

function do_uninstall{
    kubectl delete -f zookeeper/zookeeper.yaml 
    kubectl delete -f minio/minio/minio-deployment.yaml -f minio/minio-service.yaml -f minio/minio-pvc.yaml -f minio/minio-ingress.yaml -f minio/minio-namespace.yaml
    kubectl delete -f clickhouse/clickhouse-deployment.yaml
    kubectl delete -f argos/argos-deployment.yaml -f argos-ingress.yaml -f argos-pvc.yaml -f argos-role.yaml -f argos-service.yaml -f argos/argos-namespace.yaml    
}

case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
