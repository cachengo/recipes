#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

helm upgrade ingress-nginx ingress-nginx --install --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.hostNetwork=true --set controller.dnsPolicy=ClusterFirstWithHostNet --set controller.kind=DaemonSet
sleep 60
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
