#!/usr/bin/env python3

import os
import subprocess
import time
import json


def is_ip_up(ip):
    response = os.system(f'ping -c 1 {ip}')
    return response == 0

def all_ips_up(hostnames):
    for host in hostnames:
        if not is_ip_up(host):
            return False
    return True


def restart_service():
    process = subprocess.Popen(
        ['service', 'argos', 'restart'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    process.communicate()


if __name__ == "__main__":
    hostnames = json.loads(os.environ['HOSTNAMES'])

    while not all_ips_up(hostnames):
        print("Waiting for all nodes to come online")

    restart_service()
