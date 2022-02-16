#!/bin/bash

export S3_ENDPOINT_URL="http://localhost:9000"
# export RTSP_URL="rtsp://localhost:8554/compressed"

print_usage() {
  printf "Usage: -r to rebuild image.";
}


# python rtsp_saver.py
r_flag="";
while getopts 'r' flag; do
  case "${flag}" in
    r) r_flag="true" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ "$r_flag" = "true" ];
then
    docker build -t cachengo/rtsp_saver .
fi

docker stop rtsp_saver
docker rm rtsp_saver

docker run -d \
  --net=host \
  --restart=always \
  -e S3_ACCESS_KEY="$S3_ACCESS_KEY" \
  -e S3_SECRET_KEY="$S3_SECRET_KEY" \
  -e S3_ENDPOINT_URL="$S3_ENDPOINT_URL" \
  -e RTSP_URL="$RTSP_URL" \
  --name rtsp_saver \
  cachengo/rtsp_saver
