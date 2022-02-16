
import glob, os, time
from subprocess import call
import subprocess

from botocore.config import Config as S3Config
from botocore.exceptions import ClientError
from boto3.s3.transfer import TransferConfig, S3Transfer
import boto3

REMOTE_IP = os.environ.get("REMOTE_IP","")
REMOTE_USERNAME = os.environ.get("REMOTE_USERNAME")
REMOTE_PASSWORD = os.environ.get('REMOTE_PASSWORD')
REMOTE_LOCATION = os.environ.get('REMOTE_LOCATION')
S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME')
S3_ACCESS_KEY = os.environ.get("S3_ACCESS_KEY","")
S3_SECRET_KEY = os.environ.get("S3_SECRET_KEY")
S3_ENDPOINT_URL = os.environ.get('S3_ENDPOINT_URL')

MOUNT_PATH = '/mnt/upload'

s3config = S3Config(signature_version='s3v4')
s3config.s3 = {'use_dualstack_endpoint': True}


def check_remote_up():
    response = os.system(f'ping -c 1 {REMOTE_IP}')
    return response == 0

def do_mount():
    return True
    if os.path.ismount(MOUNT_PATH):
        #Maybe do unmount
        return True
    else:
        response = os.system(f'mount -t cifs -o username={REMOTE_USERNAME},vers=2.0,password={REMOTE_PASSWORD} //{REMOTE_IP}/{REMOTE_LOCATION} {MOUNT_PATH}')
        fileList = glob.glob(os.path.join(MOUNT_PATH, '*.mp4.*'))
        for filePath in fileList:
            try:
                os.remove(filePath)
            except:
                print("Error while deleting file : ", filePath)
        return response == 0


s3 = boto3.client(
    's3',
    aws_access_key_id=S3_ACCESS_KEY,
    aws_secret_access_key=S3_SECRET_KEY,
    endpoint_url=S3_ENDPOINT_URL,
    config=s3config
)
if not os.path.exists(MOUNT_PATH):
    os.makedirs(MOUNT_PATH)

while True:
    if not check_remote_up():
        print('Sleeping')
        time.sleep(5)
    else:
        print('Online')
        if do_mount():
            print('Mounted')
            for obj in s3.list_objects(Bucket=S3_BUCKET_NAME).get('Contents', []):
                try:
                    print(f"Backing up {obj['Key']}")
                    save_to = obj['Key']
                    if os.path.exists(save_to):
                        os.remove(save_to)
                    print("Downloading file")
                    s3.download_file(S3_BUCKET_NAME, obj['Key'], save_to)
                    print("Uploading file")
                    result = subprocess.run(['./ftp-script.sh', save_to], stdout=subprocess.PIPE) 
                    print("FTP done")
                    if result.stdout.count(b'Operation successful') == 2:
                        print('Upload failed, restarting')
                        print(result)
                        break
                    else:
                        print('Upload successful')
                    s3.delete_object(Bucket=S3_BUCKET_NAME, Key=obj['Key'])
                    os.remove(save_to)
                except Exception as e:
                    print(e)
                    break
