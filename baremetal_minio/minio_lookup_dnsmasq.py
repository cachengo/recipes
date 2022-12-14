#!/usr/bin/env python3

import os
import subprocess
import time
import json


def is_ip_up(ip):
    response = os.system(f'ping -c 1 {ip}')
    return response == 0

def all_ips_up(hostnames,host_num):
    ip_num = 0
    for host in hostnames:
        if is_ip_up(host):
            ip_num+=1
    if ip_num >= host_num//2:
        return True
    return False


def restart_service():
    process = subprocess.Popen(
        ['service', 'minio', 'restart'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    process.communicate()

def restart_dns():
    process = subprocess.Popen(
        ['service', 'dnsmasq', 'restart'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    process.communicate()

if __name__ == "__main__":
    hostnames = json.loads(os.environ['HOSTNAMES'])
    host_num = len(hostnames)
    while not all_ips_up(hostnames,host_num):
        print("Waiting for all nodes to come online")
        restart_dns()
        time.sleep(5)
    restart_service()
