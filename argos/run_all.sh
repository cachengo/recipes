#!/bin/bash

#Benchmark 2
# IPS=(
#     fde5:ef2d:1377:a294:3e99:9360:cfa2:2bb6
# fde5:ef2d:1377:a294:3e99:93ef:e9e0:b278
# fde5:ef2d:1377:a294:3e99:93a3:b550:fee4
# fde5:ef2d:1377:a294:3e99:9399:1e9e:12fb
# fde5:ef2d:1377:a294:3e99:932d:c02:e827
# fde5:ef2d:1377:a294:3e99:9344:8c1b:228d
# fde5:ef2d:1377:a294:3e99:93fc:4419:c912
# fde5:ef2d:1377:a294:3e99:9389:ce99:a176
# fde5:ef2d:1377:a294:3e99:9330:d6cf:7d30
# fde5:ef2d:1377:a294:3e99:934f:7a2b:963b
# fde5:ef2d:1377:a294:3e99:9353:22dd:96fe
# fde5:ef2d:1377:a294:3e99:933c:8c8d:c3a6
# fde5:ef2d:1377:a294:3e99:9336:a834:25b1
# fde5:ef2d:1377:a294:3e99:932c:dbe5:c106
# fde5:ef2d:1377:a294:3e99:931d:a39e:62d8
# fde5:ef2d:1377:a294:3e99:9319:b078:46fb
# fde5:ef2d:1377:a294:3e99:931c:b262:6d3
# fde5:ef2d:1377:a294:3e99:93b6:3758:4c18
# fde5:ef2d:1377:a294:3e99:93ab:7d7a:878d
# fde5:ef2d:1377:a294:3e99:9347:2e1f:6393
# fde5:ef2d:1377:a294:3e99:9337:6645:ddeb
# fde5:ef2d:1377:a294:3e99:9303:34d6:b808
# fde5:ef2d:1377:a294:3e99:93a4:4e38:f4a
# fde5:ef2d:1377:a294:3e99:9333:8b9a:bce7
# fde5:ef2d:1377:a294:3e99:93b3:71c4:478
# fde5:ef2d:1377:a294:3e99:93df:100:dcd1
# fde5:ef2d:1377:a294:3e99:936b:39ec:c07f
# fde5:ef2d:1377:a294:3e99:932e:6f38:9c75
# fde5:ef2d:1377:a294:3e99:93d1:51c0:2281
# fde5:ef2d:1377:a294:3e99:93ea:5f0f:a1ad
# fde5:ef2d:1377:a294:3e99:93f0:ddbe:181c
# fde5:ef2d:1377:a294:3e99:9379:a436:cfcb
# )

SERVERS=(
    192.168.89.91
    192.168.89.3
    192.168.89.64
    192.168.89.104
    192.168.89.7
    192.168.89.19
    192.168.89.18
    192.168.89.15
    192.168.89.103
    192.168.89.16
    192.168.89.29
    192.168.89.24
    192.168.89.11
    192.168.88.254
    192.168.88.252
    192.168.89.1
    192.168.89.2
    192.168.89.0
    192.168.89.14
    192.168.89.22
    192.168.89.4
    192.168.89.9
    192.168.89.8
    192.168.89.65
    192.168.89.6
    192.168.89.20
    192.168.88.253
    192.168.89.21
    192.168.89.10
    192.168.89.17
    192.168.89.5
    192.168.89.13
)

# Benchmark 1
IPS=(
    fde5:ef2d:1377:3256:5f99:936a:dad9:e5af
    fde5:ef2d:1377:3256:5f99:93b2:5c4d:2949
    fde5:ef2d:1377:3256:5f99:93cc:cd76:3f2e
    fde5:ef2d:1377:3256:5f99:935c:eeb0:7216
    fde5:ef2d:1377:3256:5f99:93e8:3003:6749
    fde5:ef2d:1377:3256:5f99:9324:8d9e:c5d7
    fde5:ef2d:1377:3256:5f99:93b7:2366:de1c
    fde5:ef2d:1377:3256:5f99:930e:f85e:4676
    fde5:ef2d:1377:3256:5f99:93c1:f939:e878
    fde5:ef2d:1377:3256:5f99:93b4:a27:4e02
    fde5:ef2d:1377:3256:5f99:936d:3a56:9d39
    fde5:ef2d:1377:3256:5f99:93e3:fa28:5fd6
    fde5:ef2d:1377:3256:5f99:9305:9228:7e95
    fde5:ef2d:1377:3256:5f99:9336:4e9f:2c3
    fde5:ef2d:1377:3256:5f99:93db:12d6:956c
    fde5:ef2d:1377:3256:5f99:9325:2f1e:a8fe
    fde5:ef2d:1377:3256:5f99:9391:7624:3e12
    fde5:ef2d:1377:3256:5f99:93ba:684a:fbe8
    fde5:ef2d:1377:3256:5f99:9327:7e98:cf77
    fde5:ef2d:1377:3256:5f99:93a6:621a:2593
    fde5:ef2d:1377:3256:5f99:9328:ce18:8c1d
    ## fde5:ef2d:1377:3256:5f99:9328:838:89c3
    fde5:ef2d:1377:3256:5f99:9380:a72e:6c5c
    fde5:ef2d:1377:3256:5f99:93e1:c55:913e
    fde5:ef2d:1377:3256:5f99:9328:45cd:7d3e
    fde5:ef2d:1377:3256:5f99:933e:a01a:1d7e
    fde5:ef2d:1377:3256:5f99:9320:b196:b303
    fde5:ef2d:1377:3256:5f99:93a4:eb4c:fb0c
    fde5:ef2d:1377:3256:5f99:93b2:7fef:2df9
    fde5:ef2d:1377:3256:5f99:93d8:4a9b:a6f2
    fde5:ef2d:1377:3256:5f99:93ac:def9:8bd
    fde5:ef2d:1377:3256:5f99:9311:a77d:a162
)

# for ((i=0;i<${#IPS[@]};++i)); do
    # ssh -t cachengo@${IPS[i]} "echo 'cachengo ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo"
    # scp minio_install.sh cachengo@[${IPS[i]}]:~/minio_install.sh
    # scp minio.service cachengo@[${IPS[i]}]:~/minio.service
    # ssh -t cachengo@${IPS[i]} "sudo /home/.cachengo/minio_install.sh install"
    # ssh -t cachengo@${IPS[i]} "sudo service minio stop"
# done

# for ((i=0;i<${#IPS[@]};++i)); do
    # ssh -t cachengo@${IPS[i]} "echo 'cachengo ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo"
    # scp mesh_install.sh cachengo@[${IPS[i]}]:~/mesh_install.sh
    # scp mesh.service cachengo@[${IPS[i]}]:~/mesh.service
    # ssh -t cachengo@${IPS[i]} "sudo /home/.cachengo/mesh_install.sh install"
    # ssh -t cachengo@${IPS[i]} "sudo service mesh stop"
# done

# for ((i=0;i<${#IPS[@]};++i)); do
    # scp minio_install.sh cachengo@[${IPS[i]}]:~/minio_install.sh
    # ssh -t cachengo@${IPS[i]} "ps ax | grep minio | grep -v grep | awk '"'{print $1}'"' | xargs kill -9"
    # ssh -t cachengo@${IPS[i]} "sudo /home/.cachengo/minio_install.sh install"
    # ssh -t cachengo@${IPS[i]} "docker stop jimmy-minio && docker rm jimmy-minio && curl -O https://dl.min.io/server/minio/release/linux-arm64/minio && chmod +x minio"
    # ssh -t cachengo@${IPS[i]} "MINIO_ROOT_USER=access_key MINIO_ROOT_PASSWORD=secret_key ./minio server  http://jimmy-minio-server-{0...31}/data/"
    # ssh -t cachengo@${IPS[i]} "df"
#     ssh -t cachengo@${IPS[i]} "rm -rfR /data/*"
# done


for ((i=0;i<${#IPS[@]};++i)); do
    scp -o StrictHostKeyChecking=no warp_setup.sh cachengo@[${IPS[i]}]:~/warp_setup.sh
    # COMMAND="iperf3 -c ${SERVERS[i]} -R"
    # COMMAND="~/s3-benchmark -a access_key -s secret_key -t 1 -z 1G -u http://${SERVERS[i]}:9000"' -b bench-`echo $HOSTNAME | awk '"'"'{print tolower($0)}'"'"'`'
    # ssh -t cachengo@${IPS[i]} "echo $COMMAND > ~/run_iperf.sh"
    ssh -t cachengo@${IPS[i]} "sudo ./warp_setup.sh install"
    # ssh -t cachengo@${IPS[i]} "df"
#     ssh -t cachengo@${IPS[i]} "echo 'cachengo ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo"
done

### Turn ON Neon 
### 
