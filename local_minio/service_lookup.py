#!/usr/bin/env python3

import os
import subprocess
import time
import json

def get_avahi_data():
    try:
        process = subprocess.Popen(
            ['avahi-browse', '-r', '--domain=local', '_cachengo._tcp', '-p', '-k', '-c'],
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE
        )
        stdout, _ = process.communicate()
        return stdout
    except:
        return ''


def parse_avahi_data(data, interface='eth0', ip_type='IPv4'):
    lines = data.splitlines()
    result = {}
    for line_b in lines:
        line = line_b.decode("utf-8")
        if line[0] != '=':
            continue
        info = line.split(';')
        if info[1] != interface or info[2] != ip_type:
            continue
        result[info[3]] = info[7]
    return result


def is_ip_up(ip):
    response = os.system(f'ping -c 1 {ip}')
    return response == 0


def set_ip_for_host(hostname, ip):
    filename = '/etc/hosts'
    with open(filename, "r") as f:
        lines = f.readlines()

    with open(filename, "w+") as f:
        for line in lines:
            if hostname not in line:
                f.write(line)
        f.write(f'{ip} {hostname}\n')


def restart_service():
    process = subprocess.Popen(
        ['service', 'minio', 'restart'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    process.communicate()


def fetch_parse_avahi():
    return parse_avahi_data(get_avahi_data())


if __name__ == "__main__":

    # hostnames = ['B020111-958092d', 'B020112-9a4ebf6', 'B020113-2c652b2', 'B020114-8c52d97', 'B020111-ddd4188', 'B020122-5b92ff2', 'B020123-461cda3', 'B020124-0689480']
    hostnames_json = open("/usr/bin/minio_lookup_hostnames.json","r")
    jsonString = hostnames_json.readline()
    hostnames = json.loads(jsonString)

    host_ip = {host: None for host in hostnames}

    while True:
        change_detected = False
        data_fetched = False

        for i, hostname in enumerate(hostnames):
            if host_ip[hostname] is None or not is_ip_up(host_ip[hostname]):
                if not data_fetched:
                    info = fetch_parse_avahi()
                    data_fetched = True
                tries = 0
                is_up = False
                while not is_up and tries <= 10:
                    name = hostname + f"-{tries}" if tries > 0 else hostname
                    new_ip = info.get(name)
                    if new_ip is not None:
                        is_up = is_ip_up(new_ip)
                        print(f'Is up: {new_ip}')
                    tries += 1
                    print('Try finished')
                if is_up:
                    print('Will set ip')
                    set_ip_for_host(f'minio-server-{i}', new_ip)
                    host_ip[hostname] = new_ip
                    change_detected = True

        if change_detected:
            print('Restarting service')
            restart_service()
        else:
            print('No changes')

        time.sleep(50)
