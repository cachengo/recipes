#!/bin/bash
HOST=10.29.96.219
USER=video
PASSWORD=test123

/usr/bin/ftp -invp $HOST <<EOF
user $USER $PASSWORD
binary
cd cachengo
put $1
bye
EOF
