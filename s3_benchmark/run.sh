#!/bin/bash

source "utils/cachengo.sh"
source "utils/parameters.sh"

function do_install {
  if [ "$(uname -m)" == 'aarch64' ]; then
    ARCH=arm64
  else
    ARCH=amd64
  fi
  
  local CLIENT_ARR
  array_from_json_list CLIENT_ARR "$CLIENTS"

  local SERVER_ARR
  array_from_json_list SERVER_ARR "$SERVERS"

  apt install -y pssh git
  cd /tmp
  curl -L -O https://golang.org/dl/go1.16.7.linux-$ARCH.tar.gz
  tar -C /tmp -xzf go1.16.7.linux-$ARCH.tar.gz
  git clone https://github.com/wasabi-tech/s3-benchmark.git
  cd s3-benchmark
  sed -i 's/github.com\/pivotal-golang\/bytefmt/code.cloudfoundry.org\/bytefmt/g' s3-benchmark.go
  /tmp/go/bin/go mod init github.com/wasabi-tech/s3-benchmark
  /tmp/go/bin/go mod tidy
  /tmp/go/bin/go build s3-benchmark.go

  for ((i=0;i<${#CLIENT_ARR[@]};++i)); do
    ssh -i /etc/cachengo/private.pem cachengo@${CLIENT_ARR[i]} sudo echo "${SERVER_ARR[i]} $GROUPID" >> /etc/hosts
    if [[ $string == *":"* ]]; then
      scp -i /etc/cachengo/private.pem s3-benchmark cachengo@[${CLIENT_ARR[i]}]:/tmp/s3-benchmark
    else
      scp -i /etc/cachengo/private.pem s3-benchmark cachengo@${CLIENT_ARR[i]}:/tmp/s3-benchmark
    fi 
    HOSTS="$HOSTS cachengo@${CLIENT_ARR[i]}"
  done

  parallel-ssh -O "StrictHostKeyChecking=no" \
    --timeout=0 \
    --host="$HOSTS" \
    -x "-i /etc/cachengo/private.pem" \
    -i "/tmp/s3-benchmark -a "$ACCESS_KEY" -s "$SECRET_KEY" -u http://$GROUPID:9000 -z 10M -t 4 -b `hostname | awk '{print tolower($0)}'` -d 1"

}

function do_uninstall {
  cachengo-cli updateInstallStatus $APPID "Uninstalling"
  rm -rf /data/dist_minio
  sed -i "/$GROUPID/d" /etc/hosts
  cachengo-cli updateInstallStatus $APPID "Uninstalled"
}


case "$1" in
  install) do_install ;;
  uninstall) do_uninstall ;;
esac