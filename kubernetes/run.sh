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

  #Initialization happens conditionally depending if the machine is a master or a worker node
  if [$KUBERNETES_TKN == '']; then
    kubeadm init --apiserver-advertise-address=$ADVERTISE_ADDRESS --skip-token-print --skip-certificate-key-print
    mkdir -p /home/kubernetes/.kube
    cp -i /etc/kubernetes/admin.conf /home/kubernetes/.kube/config 
    chown -R kubernetes /home/kubernetes/.kube
    chown kubernetes /home/kubernetes/.kube/config
  
    sudo -u kubernetes kubectl apply -f kubernetes/calico.yaml

    #Sets two env variables needed to provide the app secrets to the Cachengo portal.
    KUBERNETES_TKN=$(sudo kubeadm token list | awk 'NR == 2 {print $1}')
    KUBERNETES_CERT=$(openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1)  

    declare_secret join-token "${KUBERNETES_TKN}"
    declare_secret sha-ca-cert "${KUBERNETES_CERT}"
  else
    kubeadm join [$ADVERTISE_ADDRESS]:6443 --token $KUBERNETES_TKN --discovery-token-ca-cert-hash sha256:$KUBERNETES_CERT 
  fi

 cachengo-cli updateInstallStatus $APPID "Installed"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  kubeadm reset -f
  sudo userdel -r kubernetes
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}

function declare_secret {
  cachengo-cli declareSecret -i $APPID -n $1 -v $2
}

case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
