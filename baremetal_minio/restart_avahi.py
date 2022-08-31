#!/usr/bin/env python3

import os
import subprocess
import time
import json

def check_for_ips():
    group_id = os.environ["GROUP_ID"]
    hostnames = json.loads(os.environ['HOSTNAMES'])
    filename = '/etc/hosts'
    with open(filename, "r") as f:
        lines = f.readlines()
    for i, hostname in enumerate(hostnames):
        for line in lines:
            if f'{group_id}-{i}' in line:
                print('line found')
                line_found = True
                break
            else:
                line_found = False
        if not line_found:
            print('fail')
            return False
    return True

def restart_avahi():
    os.system('sudo systemctl restart avahi-daemon')

if __name__ == "__main__":
    restart_avahi()
    while True:
        if not check_for_ips():
            restart_avahi()
        time.sleep(50)
