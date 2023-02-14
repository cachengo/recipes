#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm upgrade ingress-nginx ingress-nginx --install --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.hostNetwork=true --set controller.dnsPolicy=ClusterFirstWithHostNet --set controller.kind=DaemonSet
sleep 60
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
