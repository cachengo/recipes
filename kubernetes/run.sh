#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  cachengo-cli updateInstallStatus $APPID "Installing K8s"
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
  echo 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >>/etc/apt/sources.list.d/kubernetes.list' | sudo -s
  apt-get update
  apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common \
      build-essential \
      docker.io \
      kubelet \
      kubeadm \
      kubectl
  swapoff -a

  cachengo-cli updateInstallStatus $APPID "Starting K8s"
  if [ "$(uname -m)" == 'aarch64' ]; then
    ARCH=arm64
    ETCD_IMAGE=quay.io/coreos/etcd:v3.3.9-arm64
    UNSUPPORTED_ARCH=arm64
  else
    ARCH=amd64
    ETCD_IMAGE=quay.io/coreos/etcd:v3.3.9
  fi

  # Start Kubernetes
  modprobe -r ipip
  rm -rf /var/etcd/
  rm -rf /var/lib/etcd/
  rm -rf /etc/kubernetes/
  ip route flush proto bird
  rm -rf $HOME/.kube
  sysctl net.bridge.bridge-nf-call-iptables=1
  kubeadm init \
    --pod-network-cidr=$POD_NET_CIDR
    --cluster-cidr=$POD_NET_CIDR
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

  # Taint the master node
  kubectl taint nodes --all node-role.kubernetes.io/master-

  cachengo-cli updateInstallStatus $APPID "Sarting Calico"
  # Set up Calico
  wget https://raw.githubusercontent.com/cachengo/seba_charts/master/scripts/etcd.yaml
  wget https://raw.githubusercontent.com/cachengo/seba_charts/master/scripts/calico.yaml

  {% raw %}
  sed "s;{{etcd_image}};$ETCD_IMAGE;g" etcd.yaml > etcd.yaml.tmp
  sed -i "s/{{unsupported_arch}}/$UNSUPPORTED_ARCH/g" etcd.yaml.tmp
  sed "s;{{pod_net_cidr}};$POD_NET_CIDR;g" calico.yaml > calico.yaml.tmp
  {% endraw %}
  kubectl apply -f etcd.yaml.tmp
  kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/rbac.yaml
  kubectl apply -f calico.yaml.tmp
  rm etcd.yaml


  # Setup helm
  cachengo-cli updateInstallStatus $APPID "Installing Helm"
  wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.3-linux-$ARCH.tar.gz
  tar -xvf helm-v2.12.3-linux-$ARCH.tar.gz
  cp linux-$ARCH/helm /usr/bin
  cp linux-$ARCH/tiller /usr/bin
  rm helm-v2.12.3-linux-$ARCH.tar.gz
  rm -rf linux-$ARCH
  if [ $ARCH == 'arm64' ]; then
    helm init --tiller-image=jessestuart/tiller:v2.9.1
  else
    helm init
  fi
  kubectl create serviceaccount --namespace kube-system tiller
  kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
  kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

  cachengo-cli updateInstallStatus $APPID "Waiting for node"
  sleep 30
  if [ $(kubectl get nodes -o=jsonpath="{.items[0].status.conditions}" | grep -c "status:True type:Ready") -eq 1 ]
  then
      cachengo-cli updateInstallStatus $APPID "Installed"
      echo -n "Installation Success"
  else
      cachengo-cli updateInstallStatus $APPID "Installation Failure"
      echo "Installation Failure"
      return 1
  fi
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