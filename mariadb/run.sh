#!/bin/bash

source "utils/cachengo.sh"

function do_install {
 set -e
 cachengo-cli updateInstallStatus "$APPID" "Installing"
 docker run \
 -d \
 --name "$APPID" \
 -e MARIADB_USER="$DB_USER" \
 -e MARIADB_PASSWORD="$DB_PASSWORD" \
 -e MARIADB_DATABASE="$DATABASE_NAME" \
 -e MARIADB_ROOT_PASSWORD="$ROOT_PASSWORD" \
 -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD="$ALLOW_EMPTY_ROOT_PASSWORD" \
 -e MARIADB_RANDOM_ROOT_PASSWORD="$RANDOM_ROOT_PASSWORD" \
 -v "/data/$APPID":/var/lib/mysql \
 -p "$HOST_PORT":3306 \
 --network $NETWORK \
 mariadb:10.7
 cachengo-cli updateInstallStatus "$APPID" "Installed"
}

function do_uninstall {
 cachengo-cli updateInstallStatus "$APPID" "Uninstalling"
 docker stop "$APPID"
 docker rm "$APPID"
 cachengo-cli updateInstallStatus "$APPID" "Uninstalled"
}

case "$1" in
 install) do_install ;;
 uninstall) do_uninstall ;;
esac
