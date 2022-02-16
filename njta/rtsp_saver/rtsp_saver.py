from botocore.config import Config as S3Config
from botocore.exceptions import ClientError
from boto3.s3.transfer import TransferConfig, S3Transfer
import boto3, os, time

S3_BUCKET_NAME = "mp4"
S3_ACCESS_KEY = os.environ.get("S3_ACCESS_KEY","")
S3_SECRET_KEY = os.environ.get("S3_SECRET_KEY")
S3_ENDPOINT_URL = os.environ.get('S3_ENDPOINT_URL')
s3config = S3Config(signature_version='s3v4')
s3config.s3 = {'use_dualstack_endpoint': True}
boto3.set_stream_logger('')
print('Running')
print(S3_ENDPOINT_URL)
s3 = boto3.client(
    's3',
    aws_access_key_id=S3_ACCESS_KEY,
    aws_secret_access_key=S3_SECRET_KEY,
    endpoint_url=S3_ENDPOINT_URL,
    config=s3config
)

print('Initiated client')
def uploadFileS3(filename):
    config = TransferConfig(multipart_threshold=100, max_concurrency=10,
                        multipart_chunksize=100, use_threads=True)
    print('About to print')
    print(filename, S3_BUCKET_NAME, os.path.basename(filename))
    print('Finished printing')
    s3.upload_file(filename, S3_BUCKET_NAME, os.path.basename(filename),
        ExtraArgs={ 'ACL': 'public-read', 'ContentType': 'video/mp4'},
        Config = config,
    )

# lo que está en la nueva, que en la vieja no está
def Diff(nueva, vieja):
    resultado = []
    for item in nueva:
        if item not in vieja:
            resultado.append(item)
    return resultado
    


file_list_old = []
files_in_process = dict()
files_ready =[]
completed = []

while True:
    time.sleep(20)
    #read directory files
    file_list_new = os.listdir('./mp4')

    # check for new files to add to the in-process queue
    new_files = []
    new_files = Diff(file_list_new, file_list_old)
    for new_file in new_files:
        print(f'New file found: {new_file}')
        file_size = os.stat(f'./mp4/{new_file}').st_size
        files_in_process[new_file] = file_size

    completed.clear()

    # check for any files in progress which have not had any changes since the last check
    for file in files_in_process:
        if file in new_files:
            continue
        fname = f'./mp4/{file}'
        last_known_size = files_in_process[file]
        current_size = os.stat(fname).st_size
        
        # if the size has not changed, upload
        if last_known_size == current_size:
            print(f'File {fname}  has not changed in 20 seconds. Uploading to minio.')
            uploadFileS3(fname)
            os.remove(fname)
            completed.append(file)
        else:
            # update the size in the queue
            print(f'{fname} was {last_known_size}, is now {current_size}')
            files_in_process[file] = os.stat(fname).st_size

    #remove files that are complete from the in process queue
    for file_to_remove in completed:
        print(f'Removing {file_to_remove} from in process queue.')
        files_in_process.pop(file_to_remove)

    file_list_old = file_list_new
