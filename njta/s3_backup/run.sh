#!/bin/bash

export S3_BUCKET_NAME="mp4"
export REMOTE_LOCATION='Video'
export RTSP_URL="rtsp://localhost:8554/compressed"

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
    docker build -t cachengo/s3_backup .
fi

docker stop s3_backup
docker rm s3_backup

docker run -d \
  --net=host \
  --restart=always \
  -e S3_ACCESS_KEY="$S3_ACCESS_KEY" \
  -e S3_SECRET_KEY="$S3_SECRET_KEY" \
  -e S3_ENDPOINT_URL="$S3_ENDPOINT_URL" \
  -e RTSP_URL="$RTSP_URL" \
  -e S3_BUCKET_NAME="$S3_BUCKET_NAME" \
  -e REMOTE_IP="$REMOTE_IP" \
  -e REMOTE_USERNAME="$REMOTE_USERNAME" \
  -e REMOTE_PASSWORD="$REMOTE_PASSWORD" \
  -e REMOTE_LOCATION="$REMOTE_LOCATION" \
  -e FTP_HOST="$FTP_HOST" \
  -e FTP_USER="$FTP_USER" \
  -e FTP_PASSWORD="$FTP_PASSWORD" \
  --cap-add SYS_ADMIN \
  --cap-add DAC_READ_SEARCH \
  --name s3_backup \
  cachengo/s3_backup
