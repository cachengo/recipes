#!/bin/bash

source "utils/cachengo.sh"

function wait_for {
    (
      local sleep_time=3
      local total_wait=$1
      the_test=$2

      local time_taken=0
      until $the_test
      do
          sleep $sleep_time
          time_taken=$(($time_taken+$sleep_time))
          if [ "$time_taken" -gt "$total_wait" ]; then
              echo "Operation timed out: $3"
              exit 1
          fi
      done
      $the_test || exit 1
    )
}

function do_install {
  set -e

  CORD_REPO=${CORD_REPO:-https://charts.opencord.org}
  CORD_PLATFORM_VERSION=${CORD_PLATFORM_VERSION:-6.1.0}
  SEBA_VERSION=${SEBA_VERSION:-1.0.0}
  ATT_WORKFLOW_VERSION=${ATT_WORKFLOW_VERSION:-1.0.2}

  tiller_test() { [[ $(kubectl get pods --all-namespaces | grep -ce "tiller.*Running") -eq 1 ]]; }
  wait_for 10 tiller_test "Waiting for Tiller"

  cachengo-cli updateInstallStatus $APPID "Fetching Charts"
  if [ "$(uname -m)" == 'aarch64' ]; then
    cd /tmp/cachengo
    rm -rf cord
    git clone https://github.com/cachengo/seba_charts cord
  else
    helm repo add cord "${CORD_REPO}"
    helm repo update
  fi

  cachengo-cli updateInstallStatus $APPID "Installing CORD"
  helm install -n cord-platform cord/cord-platform --version="${CORD_PLATFORM_VERSION}"
  etcd_test() { [[ $(kubectl get crd | grep -ice etcd) -eq 3 ]]; }
  all_running_test() { [[ $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)") -eq 1 ]]; }
  wait_for 30 etcd_test "Waiting for etcd"

  cachengo-cli updateInstallStatus $APPID "Installing SEBA"
  helm install -n seba --version "${SEBA_VERSION}" cord/seba
  kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)"
  all_running_test() { [[ $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)") -eq 1 ]]; }
  wait_for 600 all_running_test "Waiting for SEBA"

  cachengo-cli updateInstallStatus $APPID "Installing Workflow"
  helm install -n att-workflow --version "${ATT_WORKFLOW_VERSION}" cord/att-workflow
  wait_for 600 all_running_test "Waiting for ATT Workflow"
  rm -rf cord
  cachengo-cli updateInstallStatus $APPID "Installed"
  echo -n "Installation Success"
}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  helm delete --purge att-workflow
  helm delete --purge seba
  helm delete --purge cord-platform
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
