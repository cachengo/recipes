import argparse, subprocess, json
from time import sleep

parser = argparse.ArgumentParser()
parser.add_argument('-a', '--api_url')
parser.add_argument('-ak', '--api_access_key')
parser.add_argument('-as', '--api_secret_key')
parser.add_argument('-v', '--validation_url')
parser.add_argument('-s3', '--s3_url')
parser.add_argument('-s3k', '--s3_access_key')
parser.add_argument('-s3s', '--s3_secret_key')
parser.add_argument('-s3b', '--s3_bucket')
parser.add_argument('-s3r', '--s3_region')
parser.add_argument('-u', '--discourse_username')
parser.add_argument('-dt', '--discourse_topic_id')
parser.add_argument('-dc', '--discourse_category')

options,other_options = parser.parse_known_args()

api_url = ""
api_access_key = ""
api_secret_key = ""
validation_url = ""
s3_url = ""
s3_access_key = ""
s3_secret_key = ""
s3_bucket = ""
s3_region = ""
discourse_username = ""
discourse_topic_id = ""
discourse_category = ""

if options.api_url:
    api_url = options.api_url
if options.api_access_key:
    api_access_key = options.api_access_key.replace("dollarsign","$").replace("percentsign","%")
if options.api_secret_key:
    api_secret_key = options.api_secret_key.replace("dollarsign","$").replace("percentsign","%")
if options.validation_url:
    validation_url = options.validation_url
if options.s3_url:
    s3_url = options.s3_url
if options.s3_access_key:
    s3_access_key = options.s3_access_key.replace("dollarsign","$").replace("percentsign","%")
if options.s3_secret_key:
    s3_secret_key = options.s3_secret_key.replace("dollarsign","$").replace("percentsign","%")
if options.s3_bucket:
    s3_bucket = options.s3_bucket
if options.s3_region:
    s3_region = options.s3_region
if options.discourse_username:
    discourse_username = options.discourse_username
if options.discourse_topic_id:
    discourse_topic_id = options.discourse_topic_id
if options.discourse_category:
    discourse_category = options.discourse_category

config_file = '/data/threat_detection/config.json'

cameras = []
for option in other_options:
    camera = {}
    cam = option.split(" ")
    camera['id'] = cam[0]
    camera['rtsp'] = cam[1]
    camera['conf'] = float(cam[2])
    camera['max_percentage'] = float(cam[3])
    camera['crops'] = []
    if len(cam) > 4:
        crops = cam[5:]
        crop_list = [crop.split(",") for crop in crops]
        for i,crop in enumerate(crop_list):
            crop_list[i] = [float(num) for num in crop]
        camera["crops"] = crop_list
          
    cameras.append(camera)
        
new_config = {
    "validation_url":validation_url,
    "api_url":api_url,
    "api_access_key":api_access_key,
    "api_secret_key":api_secret_key,
    "s3_url":s3_url,
    "s3_access_key":s3_access_key,
    "s3_secret_key":s3_secret_key,
    "s3_bucket":s3_bucket,
    "s3_region":s3_region,
    "discourse_username":discourse_username,
    "discourse_topic_id":discourse_topic_id,
    "discourse_category":discourse_category,
    "cameras":cameras,
}

new_json = json.dumps(new_config, ensure_ascii=False, indent=2)
with open(config_file, 'w+', encoding='utf-8') as f:
    f.write(new_json)

while True:
    subprocess.run(["systemctl", "restart", "threat_detection"])
    sleep(600) 
# print(other_options)
# with open('detections.conf') as f:
#     lines = f.readlines()
