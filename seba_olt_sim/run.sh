#!/bin/bash

source "utils/cachengo.sh"

function do_install {
  set -e
  cd /tmp/cachengo
  rm -rf /tmp/cachengo/cord
  git clone https://github.com/cachengo/seba_charts cord
  helm install -n bbsim cord/bbsim
  all_running_test() { [[ $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)") -eq 1 ]]; }

  TOSCA_POD=`kubectl get pods | grep xos-tosca | cut -d " " -f1`
  TOSCA_IP=`kubectl describe pod $TOSCA_POD | grep Node: | cut -d "/" -f2`
  BBSIM_IP=`kubectl get services -n voltha | grep bbsim | tr -s ' ' | cut -d " " -f3`

  # Create the first model
  curl \
    -H "xos-username: admin@opencord.org" \
    -H "xos-password: letmein" \
    -X POST \
    --data-binary @cord/scripts/fabric.yaml \
    http://$TOSCA_IP:30007/run

  # Create the second model
  sed "s/{{ '{{' }}bbsim_ip{{ '}}' }}/$BBSIM_IP/g" cord/scripts/olt.yaml > olt.yaml.tmp
  curl \
    -H "xos-username: admin@opencord.org" \
    -H "xos-password: letmein" \
    -X POST \
    --data-binary @olt.yaml.tmp \
    http://$TOSCA_IP:30007/run
  rm olt.yaml.tmp
}

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

function do_uninstall {
  # Need to figure out how to remove the added models
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  helm delete --purge bbsim
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac
