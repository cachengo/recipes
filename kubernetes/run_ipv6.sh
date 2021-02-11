#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  cachengo-cli updateInstallStatus $APPID "Installing K8s"
  sudo -i
  ufw disable #should be changed after validating no issues appear without it
  swapoff -a; sed -i '/swap/d' /etc/fstab

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
  kubeadm init --apiserver-advertise-address=$IPV6_ADDR
  
  #Pull Calico config and apply 
  wget $CALICO_URL
  kubectl apply -f calico.yaml

  exit
 
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  #Will probably need to publish part of the data returned in the join command.
  #Will need to publish the modified Calico config file
  
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  kubeadm reset -f
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
