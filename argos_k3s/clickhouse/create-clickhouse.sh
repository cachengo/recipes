#!/bin/bash

kubectl create ns clickhouse
sudo apt-get install gettext-base
curl -s https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator-web-installer/clickhouse-operator-install.sh | OPERATOR_NAMESPACE=clickhouse bash
kubectl apply -f argos_k3s/clickhouse/clickhouse-deployment.yaml