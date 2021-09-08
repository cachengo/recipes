import json
import os
import xml.etree.ElementTree as ET

APP_ID = os.environ.get('APPID') or 'plex'
IP_ADDRESSES = json.loads(os.environ.get('IP_ADDRESSES') or '[]')

xmlfile = '/data/{APP_ID}/config/Library/Application Support/Plex Media Server/Preferences.xml'.format(APP_ID=APP_ID)
tree = ET.parse(xmlfile)
root = tree.getroot()

uuid = root.attrib.get('CertificateUUID', 'uuid')
root.set('allowedNetworks', "fc00:0000:0000:0000:0000:0000:0000:0000/7,172.17.0.0/16,127.0.0.1")
custom_connections = [
    'https://{ip}.{uuid}.plex.direct:32400'.format(uuid=uuid, ip=ip.replace('.', '-').replace(':', '-'))
    for ip in IP_ADDRESSES
]
root.set('customConnections', ','.join(custom_connections))
print(','.join(custom_connections))

header = '<?xml version="1.0" encoding="utf-8"?>\n'
data = ET.tostring(root)
with open(xmlfile, "w") as f:
    f.write(header+data)