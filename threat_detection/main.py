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

import queue, threading, time, ffmpeg, argparse

# parser = argparse.ArgumentParser()
# parser.add_argument('-v', '--validate')
# parser.add_argument('-d','-discourse')
# options = parser.parse_args()


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

with open('detections.conf') as f:
    lines = f.readlines()
    for line in lines:
        cam = line.split()
        if len(cam) == 1:
            new_line = cam[0].split("=")
            if new_line[0] == "VALIDATION_URL":
                validation_url = new_line[1]
            if new_line[0] == "API_URL":
                api_url = new_line[1]
            if new_line[0] == "API_ACCESS_KEY":
                api_access_key = new_line[1]
            if new_line[0] == "API_SECRET_KEY":
                api_secret_key = new_line[1]
            if new_line[0] == "S3_URL":
                s3_endpoint = new_line[1]
            if new_line[0] == "S3_ACCESS_KEY":
                s3_access_key = new_line[1]
            if new_line[0] == "S3_SECRET_KEY":
                s3_secret_key = new_line[1]
            if new_line[0] == "S3_BUCKET":
                s3_bucket = new_line[1]
            if new_line[0] == "S3_REGION":
                s3_region = new_line[1]
            if new_line[0] == "DISCOURSE_USERNAME":
                discourse_username = new_line[1]
            if new_line[0] == "DISCOURSE_TOPIC_ID":
                discourse_topic_id = new_line[1]
            if new_line[0] == "DISCOURSE_CATEGORY":
                discourse_category = new_line[1]
        if len(cam) > 4:
            crop_list = []
            num_crops = int(cam[4])
            crops = cam[5].split(',')
            for i in range(num_crops):
                crop_list2 = []
                for n in range(4):
                    crop_list2.append(float(crops.pop(0)))
                crop_list.append(crop_list2)

            cameras.append({"id":cam[0], "rtsp":cam[1], "conf":float(cam[2]), "max_percentage":float(cam[3]),"crops":crop_list})
        else:
            cameras.append({"id":cam[0], "rtsp":cam[1], "conf":float(cam[2]), "max_percentage":float(cam[3]),"crops":[]})

s3config = S3Config(signature_version='s3v4')
s3config.s3 = {'use_dualstack_endpoint': True}

# s3_access_key = os.environ['S3_ACCESS_KEY']
# s3_secret_key = os.environ['S3_SECRET_KEY']
# s3_endpoint = os.environ['S3_ENDPOINT']
# s3_region = os.environ['S3_REGION']
# s3_bucket = os.environ['S3_BUCKET']
model_path = os.environ['MODEL']
# api_url = os.environ['BEMOTION_URL']
# api_access_key = "asd@#$fdsf4yh*^%^3gfds2dgdfH%3DfSDvqrt2tg099sdjfsdds_dg_dK_EMN_DETECTION"
# api_secret_key = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImVtbkBlbW4uY29tIiwibmFtZSI6IkFobWFkIE1hdGthcmkiLCJ1c2VySWQiOjk5OTk5OTk5OTk5LCJub3ciOiIyMDIzLTAxLTAxVDA5OjMwOjMyKzAyOjAwIiwiaXNEZXRlY3Rpb24iOnRydWUsImxhbmd1YWdlSWQiOjF9.l7DgI2sMccAn1CsPhHBcS9ts09SCoBYj92z1CTLZtZk"

if s3_endpoint:
    s3 = boto3.client(
        's3',
        region_name=s3_region,
        aws_access_key_id=s3_access_key,
        aws_secret_access_key=s3_secret_key,
        endpoint_url=s3_endpoint,
        config=s3config
    )

def save_file(s3, s3_bucket,filename, data):
    s3.put_object(
        Body=data,
        Bucket=s3_bucket,
        Key=filename
    )

def get_file(s3, s3_bucket, filename):
    url = s3.generate_presigned_url(
        'get_object',
        Params={
            'Bucket': s3_bucket,
            'Key': filename
        },
        ExpiresIn=604800,
    )
    return url

# s3_ampere = boto3.client(
#     's3',
#     # #region_name=s3_region,
#     aws_access_key_id="cachengo",
#     aws_secret_access_key="cachengo",
#     endpoint_url="http://35.130.101.197:9000",
#     config=s3config
# )
def get_video_size(filename):
    probe = ffmpeg.probe(filename)
    video_info = next(s for s in probe['streams'] if s['codec_type'] == 'video')
    width = int(video_info['width'])
    height = int(video_info['height'])
    return width, height

validation_url = 'http://validation.cachengo.com/api/auth/detections'

detection_classes = ['Firearm']

def crop_frames(frames,cameras):
    new_frames = []
    for i,cam in enumerate(cameras):
        if len(cam['crops']) == 0:
            new_frames.append(frames[i])
        else:
            h = frames[i].shape[0]
            w = frames[i].shape[1]
            for crop in cam['crops']:
                new_frames.append(frames[i][round(h*crop[0]):round(h*crop[1]),round(w*crop[2]):round(w*crop[3])])
    return new_frames

def combine_results(results,cameras,frames):
    cam_results = []
    for i,cam in enumerate(cameras):
        if len(cam['crops']) == 0:
            cam_results.append([results.pop(0)])
        else:
            temp_results = []
            for crop in cam['crops']:
                result = results.pop(0)
                #if len(result[0]) > 0:
                if len(result) > 0:
                    h = frames[i].shape[0]
                    w = frames[i].shape[1]

                    top = round(h*crop[0])
                    bottom = round(h-(h*crop[1]))
                    left = round(w*crop[2])
                #right = round(w-(w*.7))
                    right = round(w-(w*crop[3]))

                    result = resize_label(result,top,bottom,left,right,frames[i].shape)
                for res in result:
                    for n in range(res.shape[0]):
                        temp_results.append(res.tolist()[n])
            cam_results.append([torch.Tensor(temp_results)])
    return cam_results

def resize_label(results, top, bottom, left, right, bg_size):
     best_score = np.argmax([result[4] for result in results])
     x = results[best_score][0]
     y = results[best_score][1]
     x1 = results[best_score][2]
     y1 = results[best_score][3]

     dx = results[best_score][2] - x
     dy = results[best_score][3] - y

     x = x+left
     y = y+top
     class_num = results[best_score][5]
     score = results[best_score][4]
     #x = int(x * resize)
     #y = int(y * resize)
     #dx = int(dx * resize)
     #dy = int(dy * resize)
     #x += x_loc
     #y += y_loc
    #  label = "0 {} {} {} {}".format((x+dx/2)/bg_size[1], (y+dy/2)/bg_size[0], dx/bg_size[1], dy/bg_size[0])
     return [torch.FloatTensor([[x, y, x+dx, y+dy, score, class_num]])]

#def resize_label(results, top, bottom, left, right, bg_size):
    # best_score = np.argmax([result[4] for result in results[0]])
#    new_results = []
    #for result in results[0]:
#    for result in results:
#        class_num = float(result[-1])
#        score = math.floor(100*float(result[-2]))/100
#        x = result[0]
#        y = result[1]
#        x1 = result[2]
#        y1 = result[3]

#        dx = result[2] - x
#        dy = result[3] - y

#        x = x+left
#        y = y+top
        #x = int(x * resize)
        #y = int(y * resize)
        #dx = int(dx * resize)
        #dy = int(dy * resize)
        #x += x_loc
        #y += y_loc
 #       label = "{} {} {} {} {}".format(class_num, (x+dx/2)/bg_size[1], (y+dy/2)/bg_size[0], dx/bg_size[1], dy/bg_size[0])
 #       new_results.append(torch.FloatTensor([[x, y, x+dx, y+dy, score, class_num]]))
 #   return new_results

def run_inference_for_video():
    start_cams(cameras)
    stream_up = [False for rtsp in cameras]
    start_time = [None for rtsp in cameras]
    while True:
        frames = read()
        cropped_frames = crop_frames(frames,cameras)
        if len(frames) >= 1:
            t_start_inference = time.time()
            total_inference_time=0
            frames = [cv.cvtColor(frame, cv.COLOR_BGR2RGB) for frame in frames]

            results,num_detections = perform_inference_on_batch(cropped_frames,model)
            if num_detections > 0:
                camera_list = []
                for camera in cameras:
                    if len(camera["crops"]) > 0:
                        for crop in camera["crops"]:
                            camera_list.append(camera)
                    else:
                        camera_list.append(camera)
                num_detections = 0
                for i,cropped_frame in enumerate(cropped_frames):
                    results[i],det_count = filter(results[i], cropped_frame, camera_list[i])
                    num_detections+=det_count
                if num_detections > 0:
                    results = combine_results(results,cameras,frames)

            total_inference_time += time.time() - t_start_inference
            print("Inference took: "+str(total_inference_time) + "s")
            print("Results: "+ str(results))

            if num_detections > 0:
                now = datetime.now()
                dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
                for i,result in enumerate(results):
                    # result,scores = filter(result,frames[i],cameras[i])
                    if len(result[0]) > 0:
                        # score = scores[0]
                        scores = []
                        for detected_object in result:
                            for n in range(detected_object.shape[0]):
                                print(detected_object)
                                score = math.floor(100*float(detected_object[n][-2]))/100
                                scores.append(score)
                        score = max(scores)
                        label = "Firearm "
                        overlay_image_orig = overlay_boxes(frames[i],result,label)
                        overlay_image_orig = cv.resize(np.array(overlay_image_orig), (1920,1080))
                        print("Date" + dt_string)
                        im = cv.imencode('.jpg', frames[i])[1].tobytes()
                        newId = str(uuid.uuid4())
                        # try:
                        #     save_file(s3, s3_bucket, f"{cameras[i]['id']}-image-{newId}-nb.jpg", im)
                        #     url = get_file(s3, s3_bucket, f"{cameras[i]['id']}-image-{newId}-nb.jpg")
                        #     print(dt_string)
                        # except Exception as e:
                        #     print("Couldn't save to Amazon S3: ", e)
                        #     break
#                        try:
#                            save_file(s3_ampere, "frost-backgrounds", f"{cameras[i]['id']}-image-{newId}-nb.jpg", im)

#                        except Exception as e:
#                            print("couldn't save to Cachengo S3:", e)

                        my_table = PrettyTable()
                        my_table.field_names = ["Detection Name","Number of Detections"]
                        detection_dict = {n : 0 for n in detection_classes}

                        detection_dict['Firearm']=len(result[0])
                        for n in detection_classes:
                            my_table.add_row([n, detection_dict[n]])

                        print(my_table)
                        if stream_up[i]:
                            print("stream is up")
                            now = time.time()
                            if now-start_time[i] >= 5:
                                print("Triggering alarm!")
                                stream_up[i] = validation_request(overlay_image_orig,s3,s3_bucket,cameras[i],newId,url,score)
                                start_time[i] = time.time()
                            else:
                                print(f"{now-start_time[i]} seconds have passed")
                                print("Waiting for 5 seconds to pass")
                        else:
                            print("Triggerring alarm!")
                            stream_up[i] = validation_request(overlay_image_orig,s3,s3_bucket,cameras[i],newId,url,score)
                            start_time[i] = time.time()


        else:
            break
    print('Finished video')

def validation_request(image,s3,s3_bucket,camera,id,url,score):

    try:
        im = cv.imencode('.jpg', image)[1].tobytes()

        if validation_url:
            save_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg", im)
            url = get_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg")
            print(url)
            now = time.time()
            j = {'cameraId': camera['id'], 'imageUrl': url, 'dateTime': str(now), 'imageType': 'weapon', 'bemotionUrl':api_url, 'confidence':score}
            headers = {"detection-access-key": api_access_key, "detection-access-token": api_secret_key}
            res = requests.post(validation_url, json=j, headers=headers)
        elif discourse_username:
            j = {'raw': camera['id']+" "+str(now)+"\n"+im, 'topic_id': discourse_topic_id, 'category': discourse_category}
            headers = {"Api-Key": api_access_key, "Api-Username": discourse_username}
            res = requests.post(validation_url, json=j, headers=headers)
        else:
            save_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg", im)
            url = get_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg")
            print(url)
            now = time.time()
            j = {'cameraId': camera['id'], 'imageUrl': url, 'dateTime': str(now), 'imageType': 'weapon'}
            headers = {"detection-access-key": api_access_key, "detection-access-token": api_secret_key}
            res = requests.post(api_url, json=j, headers=headers)
        print ('response from server:', res.text)
        return True
    except requests.exceptions.RequestException as e:
        print(f'Request Failed')
        return False


def perform_inference_on_batch(frames,model):
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
    intersecting_preds = []
    final_preds = []
    scores = []
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
                    scores.append(score)
                    detected_object = torch.Tensor(detected_object)
        if len(filtered_predictions):
            people_results,num_detections = perform_inference_on_batch([frame],people_model)
            print(str(len(people_results[0][0]))+" people found")
            for res in people_results[0]:
                res = res.tolist()
                for i,_ in enumerate(res):
                    if res[i][-1] == 0:
                        height = res[i][3]-res[i][1]
                        width = res[i][2]-res[i][0]
                        height_diff_bot = height*.20
                        height_diff_top = height*.25
                        res[i][3]-=height_diff_bot
                        res[i][1]-=height_diff_top
                        width_diff= width*.20
                        res[i][0]-=width_diff
                        res[i][2]+=width_diff
                        if res[i][1] < 0:
                            res[i][1] = 0
                        if res[i][0] < 0:
                            res[i][0] = 0
                        if res[i][3] > frame.shape[0]:
                            res[i][3] = frame.shape[0]
                        if res[i][2] > frame.shape[1]:
                            res[i][2] = frame.shape[1]
                        for pred in filtered_predictions:
                            x1 = pred[0]
                            y1 = pred[1]
                            x2 = pred[2]
                            y2 = pred[3]
                            if (x1 >= res[i][0] and x1 <= res[i][2]) or (x2 <= res[i][2] and x2 >= res[i][0]):
                                if (y1 >= res[i][1] and y2 <= res[i][3]):
                                    intersecting_preds.append(pred)
                                    intersecting_preds.append(res[i])
    for pred in intersecting_preds:
        height = pred[3]-pred[1]
        width = pred[2]-pred[0]
        print(pred)
        percent_diff_top = height*.50
        percent_diff_left = width*.50
        x1 = pred[0] - percent_diff_left
        y1 = pred[1] - percent_diff_top
        x2 = pred[2] + percent_diff_left
        y2 = pred[3] + percent_diff_top

        if x1 < 0:
            x1 = 0
        if x2 > frame.shape[1]:
            x2 = frame.shape[1]
        if y1 < 0:
            y1 = 0
        if y2 > frame.shape[0]:
            y2 = frame.shape[0]

        crop_frame = frame[round(y1):round(y2),round(x1):round(x2)]
        results,num_detections = perform_inference_on_batch(crop_frame,model)

        if num_detections > 0:
            for object in intersecting_preds:
                if object[-1] != 0:
                    final_preds.append(object)
            return torch.Tensor(final_preds),len(final_preds)

    # return [torch.Tensor(intersecting_preds)]
    # return [torch.Tensor(final_preds)]
    return torch.Tensor([]), 0
         #   for res in people_results[0]:
         #       res = res.tolist()
         #       for i,_ in enumerate(res):
         #           for pred in intersecting_preds:
         #               if res[i][-1] != 0:

          #                  x1 = pred[0]
          #                  y1 = pred[1]
          #                  x2 = pred[2]
          #                  y2 = pred[3]
          #                  if (res[i][0] >= x1 and res[i][0] <= x2) or (res[i][2] <= x2  and res[i][2] >= x1):
          #                      if (res[i][1] >= y1 and res[i][1] <= y2) or (res[i][3] <= y2 and res[i][3] >= y1):
          #                          continue
          #              final_preds.append(pred)
    #return torch.Tensor(final_preds),len(final_preds)

   # return torch.Tensor(filtered_predictions)

image_size=640
conf_thresh=min([c['conf'] for c in cameras])
iou_thresh=0.6
#model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path)
model = torch.hub.load('./ultralytics/yolov5', 'custom', path=model_path, source="local")
model.conf = conf_thresh
model.iou=iou_thresh
model.classes = [80]

people_model = torch.hub.load('./ultralytics/yolov5', 'custom', path='yolov5n.pt', source="local")
people_model.conf = 0.4
people_model.iou = iou_thresh
people_model.classes = [0]

while True:
    dims = [get_video_size(camera['rtsp']) for camera in cameras]
    run_inference_for_video()
