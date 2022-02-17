#!/bin/bash
HOST=$FTP_HOST
USER=$FTP_USER
PASSWORD=$FTP_PASSWORD

/usr/bin/ftp -invp $HOST <<EOF
user $USER $PASSWORD
binary
cd cachengo
put $1
bye
EOF
