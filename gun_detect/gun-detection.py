#!/usr/bin/env python3.8

import os
os.environ['OPENCV_LOG_LEVEL'] = 'OFF'
os.environ['NUMPY_LOG_LEVEL'] = 'OFF'
os.environ['OPENCV_FFMPEG_DEBUG'] = 'OFF'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import numpy as np
from bbox_utils import overlay_boxes
from yolov5_utils import *
import numpy as np
import time
import cv2 as cv
import matplotlib.pyplot as plt
from prettytable import PrettyTable
from datetime import datetime
from threading import Thread
import requests
import boto3
from botocore.config import Config as S3Config
import uuid
import math
import torch

import queue, threading, time, ffmpeg, subprocess

caps = []
q = []
dims = []
def start_cams(cameras):
    args = {
        "rtsp_transport": "tcp",
        "skip_frame": "nokey",
    }
    for stream in cameras:
        p = (
            ffmpeg
            .input(stream['rtsp'],**args)
            .filter('fps', fps=1, round='up')
            .output('pipe:', format='rawvideo', pix_fmt='rgb24')
            .global_args('-hide_banner', '-loglevel', 'error')
            .run_async(pipe_stdout=True)
        )
        caps.append(p)
        q.append(queue.Queue())
    t = threading.Thread(target=reader)
    t.daemon = True
    t.start()

def reader():
  while True:
    for i,cap in enumerate(caps):
      frame = get_next_frame(cap,dims[i][0],dims[i][1])
      if frame is None:
        break
      if not q[i].empty():
        try:
          q[i].get_nowait()   # discard previous (unprocessed) frame
        except queue.Empty:
          pass
      q[i].put((frame))

def read():
  frames = []
  for queue in q:
    frames.append(queue.get())
  return frames

def get_next_frame(proc,width,height):
    in_bytes = proc.stdout.read(width * height * 3)
    if not in_bytes:
        return None
    in_frame = (
        np
        .frombuffer(in_bytes, np.uint8)
        .reshape([height, width, 3])
    )
    return in_frame

cameras = []

with open('/data/models/detections.conf') as f:
    lines = f.readlines()
    for line in lines:
        cam = line.split()
        cameras.append({"id":cam[0], "rtsp":cam[1], "conf":float(cam[2]), "max_percentage":float(cam[3])})

# s3config = S3Config(signature_version='s3v4')
# s3config.s3 = {'use_dualstack_endpoint': True}

# s3_access_key = os.environ['S3_ACCESS_KEY']
# s3_secret_key = os.environ['S3_SECRET_KEY']
# s3_endpoint = os.environ['S3_ENDPOINT']
# s3_region = os.environ['S3_REGION']
# s3_bucket = os.environ['S3_BUCKET']

# s3 = boto3.client(
#     's3',
#   #  region_name=s3_region,
#     aws_access_key_id=s3_access_key,
#     aws_secret_access_key=s3_secret_key,
#     endpoint_url=s3_endpoint,
#     config=s3config
# )

# def save_file(s3, s3_bucket,filename, data):
#     s3.put_object(
#         Body=data,
#         Bucket=s3_bucket,
#         Key=filename
#     )

# def get_file(s3, s3_bucket, filename):
#     url = s3.generate_presigned_url(
#         'get_object',
#         Params={
#             'Bucket': s3_bucket,
#             'Key': filename
#         },
#         ExpiresIn=604800,
#     )
#     return url

def get_video_size(filename):
    probe = ffmpeg.probe(filename)
    video_info = next(s for s in probe['streams'] if s['codec_type'] == 'video')
    width = int(video_info['width'])
    height = int(video_info['height'])
    return width, height

# bemotion_url = 'http://validation.cachengo.com/api/auth/detections'

detection_classes = ['Firearm']

def run_inference_for_video():
    start_cams(cameras)
    stream_up = [False for rtsp in cameras]
    start_time = [None for rtsp in cameras]
    while True:
        frames = read()
        if len(frames) >= 1:
            t_start_inference = time.time()
            total_inference_time=0
            frames = [cv.cvtColor(frame, cv.COLOR_BGR2RGB) for frame in frames]
            results,num_detections = perform_inference_on_batch(frames)
            total_inference_time += time.time() - t_start_inference
            print("Inference took: "+str(total_inference_time) + "s")
            print("Results: "+ str(results))

            if num_detections > 0:
                now = datetime.now()
                dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
                for i,result in enumerate(results):
                    result = filter(result,frames[i],cameras[i])
                    if len(result[0]) > 0:
                        # overlay_image_orig = overlay_boxes(frames[i],result)
                        # overlay_image_orig = cv.resize(np.array(overlay_image_orig), (1920,1080))
                        print("Date" + dt_string)
                        # im = cv.imencode('.jpg', frames[i])[1].tobytes()
                        # newId = str(uuid.uuid4())
                        # save_file(s3, s3_bucket, f"{cameras[i]['id']}-image-{newId}-nb.jpg", im)
                        # url = get_file(s3, s3_bucket, f"{cameras[i]['id']}-image-{newId}-nb.jpg")
                        print(dt_string)

                        my_table = PrettyTable()
                        my_table.field_names = ["Detection Name","Number of Detections","Cam ID"]
                        detection_dict = {n : 0 for n in detection_classes}

                        detection_dict['Firearm']=len(result[0])
                        for n in detection_classes:
                            my_table.add_row([n, detection_dict[n], cameras[i]['id']])

                        print(my_table)
                        # if stream_up[i]:
                        #     print("stream is up")
                        #     now = time.time()
                        #     if now-start_time[i] >= 5:
                        #         print("Triggering alarm!")
                        #         stream_up[i] = validation_request(overlay_image_orig,s3,s3_bucket,cameras[i],newId,url)
                        #         start_time[i] = time.time()
                        #     else:
                        #         print(f"{now-start_time[i]} seconds have passed")
                        #         print("Waiting for 5 seconds to pass")
                        # else:
                        #     print("Triggerring alarm!")
                        #     stream_up[i] = validation_request(overlay_image_orig,s3,s3_bucket,cameras[i],newId,url)
                        #     start_time[i] = time.time()


        else:
            break
    print('Finished video')

def validation_request(image,s3,s3_bucket,camera,id,url):
    try:
        im = cv.imencode('.jpg', image)[1].tobytes()
        save_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg", im)
        print(url)
        now = time.time()
        j = {'cameraId': camera['id'], 'imageUrl': url, 'dateTime': str(now), 'imageType': 'weapon'}
        headers = {"detection-access-key": "asd@#$fdsf4yh(&%$#42dfH%3DfSDvqrt2tg099sdjfsdds_dg_dK_FROSTSCIENCE_DETECTION", "detection-access-token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImZyb3N0c2NpZW5jZUBmcm9zdHNjaWVuY2UuY29tIiwibmFtZSI6IkFobWFkIE1hdGthcmkiLCJ1c2VySWQiOjk5OTk5OTk5OTk5LCJub3ciOiIyMDIzLTAxLTAxVDA5OjMwOjMyKzAyOjAwIiwiaXNEZXRlY3Rpb24iOnRydWUsImxhbmd1YWdlSWQiOjF9.6ODrQsWkvp66bcORbMxPYG8car7iGFV1tNEkkitIdNc"}
        res = requests.post(bemotion_url, json=j, headers=headers)
        print ('response from BemotionInc server:', res.text)
        return True
    except requests.exceptions.RequestException as e:
        print(f'Request Failed')
        return False


def perform_inference_on_batch(frames):
    preds=[]
    dets=0
    results = model(frames, size=640)
    if len(results.xyxy) > 0:
        for result in results.xyxy:
            dets+=len(result)
            result = torch.unsqueeze(result, 0)
            preds.append(result)
    return preds,dets

def filter(predictions,frame,camera):
    filtered_predictions = []
    image_width = frame.shape[1]
    image_height = frame.shape[0]
    image_area = image_width*image_height
    for detected_object in predictions:
        for i in range(detected_object.shape[0]):
            score = math.floor(100*float(detected_object[i][-2]))/100
            if score >= camera['conf']:
                box = detected_object[i][0:4].detach().cpu().numpy()
                x1 = box[0]
                x2 = box[2]
                y1 = box[1]
                y2 = box[3]
                width = x2-x1
                height = y2-y1
                area = width*height
                ratio = area/image_area
    #            if height < width and ratio < max_percentage and ratio != 0.0:
                if ratio < camera['max_percentage'] and ratio != 0.0:
                    detected_object = detected_object.tolist()
                    filtered_predictions.append(detected_object[i])
                    detected_object = torch.Tensor(detected_object)

    return [torch.Tensor(filtered_predictions)]

image_size=640
conf_thresh=min([c['conf'] for c in cameras])
iou_thresh=0.6
model = torch.hub.load('ultralytics/yolov5', 'custom', path='/data/models/yolov5n_02-02-23_300.pt')
model.conf = conf_thresh
model.iou=iou_thresh
while True:
    dims = [get_video_size(stream['rtsp']) for stream in cameras]
    run_inference_for_video()


