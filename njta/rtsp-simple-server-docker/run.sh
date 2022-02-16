#!/bin/bash

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
    docker build -t cachengo/rtsp_server .
fi

docker stop rtsp_server
docker container rm rtsp_server

#RTSP_PATHS_TEST1_SOURCE=rtsp://rtsp.stream/pattern

docker run -d \
  --net=host \
  -e RTSP_PATHS_TEST1_SOURCE=$RTSP_URL \
  --name rtsp_server \
  cachengo/rtsp_server
