import argparse, subprocess
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
conf_string = ""
if options.api_url:
    conf_string += "API_URL="+options.api_url+"\n"+"API_ACCESS_KEY="+options.api_access_key+"\n"+"API_SECRET_KEY="+options.api_secret_key+"\n"
if options.validation_url:
    conf_string += "VALIDATION_URL="+options.validation_url+"\n"
if options.s3_url:
    conf_string += "S3_URL="+options.s3_url+"\n"+"S3_ACCESS_KEY="+options.s3_access_key+"\n"+"S3_SECRET_KEY="+options.s3_secret_key+"\n"+"S3_BUCKET="+options.s3_bucket+"\n"+"S3_REGION="+options.s3_region+"\n"    
if options.discourse_username:
    conf_string += "DISCOURSE_USERNAME="+options.discourse_username+"\n"+"DISCOURSE_TOPIC_ID="+options.discourse_topic_id+"\n"+"DISCOURSE_CATEGORY="+options.discourse_category+"\n"

conf_string += "\n".join(other_options)
print(conf_string)

with open("detections.conf","w+") as f:
    f.write(conf_string)

while True:
    subprocess.run(["systemctl", "restart", "threat_detection"])
    sleep(600) 
# print(other_options)
# with open('detections.conf') as f:
#     lines = f.readlines()
