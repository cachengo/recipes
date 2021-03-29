#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  cachengo-cli updateInstallStatus $APPID "Installing"
 
  sudo adduser kubernetes --disabled-password
  swapoff -a; sed -i '/swap/d' /etc/fstab

  sysctl -w net.ipv6.conf.all.forwarding=1

  #Will update sysctl settings
  cat >>/etc/sysctl.d/kubernetes.conf<<EOF
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
EOF
  sysctl --system

  #Install K8s and its components
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
  apt update && apt install -y kubeadm=1.18.5-00 kubelet=1.18.5-00 kubectl=1.18.5-00

  #Initialization
  kubeadm init --apiserver-advertise-address=$ADVERTISE_ADDRES --skip-token-print --skip-certificate-key-print

  mkdir -p /home/kubernetes/.kube
  cp -i /etc/kubernetes/admin.conf /home/kubernetes/.kube/config 
  chown -R kubernetes /home/kubernetes/.kube
  chown kubernetes /home/kubernetes/.kube/config
  
  sudo -u kubernetes kubectl apply -f kubernetes/calico.yaml

  cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  echo "Delete reached"
  kubeadm reset -f
  sudo userdel -r kubernetes
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}

case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
