#!/usr/bin/env python3.8

import os
os.environ['OPENCV_LOG_LEVEL'] = 'OFF'
os.environ['NUMPY_LOG_LEVEL'] = 'OFF'
os.environ['OPENCV_FFMPEG_DEBUG'] = 'OFF'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import numpy as np
from bbox_utils import overlay_boxes, scale_predictions
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

import queue, threading, time, ffmpeg, argparse, sys
from itertools import *

from rknnlite.api import RKNNLite
import rknnlite

from hide_warnings import hide_warnings

s3_access_key = None
s3_secret_key = None
s3_endpoint = None
s3_region = None
s3_bucket = None
api_url = None
api_access_key = None
api_secret_key = None
validation_url = None
discourse_username = None
discourse_topic_id = None
discourse_category = None
location = None

config = json.load(open("config.json", 'r', encoding='utf-8'))

if config['validation_url'] != "" and not config['validation_url'].isspace():
    validation_url = config['validation_url']
if config['api_url'] != "" and not config['api_url'].isspace():
    api_url = config['api_url']
    api_access_key = config['api_access_key']
    api_secret_key = config['api_secret_key']
    s3_endpoint = config['s3_url']
    s3_access_key = config['s3_access_key']
    s3_secret_key = config['s3_secret_key']
    s3_bucket = config['s3_bucket']
    s3_region = config['s3_region']
if config['discourse_username'] != "" and not config['discourse_username'].isspace():
    discourse_username = config['discourse_username']
    discourse_topic_id = config['discourse_topic_id']
    discourse_category = config['discourse_category']

cameras = config["cameras"]

if len(cameras) == 0:
    sys.exit("No cameras found in config.")
s3config = S3Config(signature_version='s3v4')
s3config.s3 = {'use_dualstack_endpoint': True}

model_path = os.environ['MODEL']

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
  #    if frame is None:
      #  break
 #       print("No frame found")
      if not q[i].empty():
        try:
          q[i].get_nowait()   # discard previous (unprocessed) frame
        except queue.Empty:
          pass
      q[i].put((frame))

def read():
  frames = []
  for ret in q:
  #  try:
    frames.append(ret.get())
  #  except queue.Empty:
  #    print("Frame not found")
  #    frames.append(None)
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

def get_video_size(filename):
    try:
      probe = ffmpeg.probe(filename)
      video_info = next(s for s in probe['streams'] if s['codec_type'] == 'video')
      width = int(video_info['width'])
      height = int(video_info['height'])
      return width, height
    except:
      print("Couldn't probe stream")
      return 0,0

detection_classes = ['Firearm']

def crop_frames(frames,cameras):
    new_frames = []
    for i,cam in enumerate(cameras):
        if len(cam['crops']) == 0:
            new_frames.append(frames[i])
        else:
            if frames[i] is not None:
              h = frames[i].shape[0]
              w = frames[i].shape[1]
            for crop in cam['crops']:
                if frames[i] is None:
                  new_frames.append(frames[i])
                  continue
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
                if len(result) > 0:
                    h = frames[i].shape[0]
                    w = frames[i].shape[1]

                    top = round(h*crop[0])
                    bottom = round(h-(h*crop[1]))
                    left = round(w*crop[2])
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

     return [torch.FloatTensor([[x, y, x+dx, y+dy, score, class_num]])]


def run_inference_for_video():
    start_cams(cameras)
    stream_up = [False for rtsp in cameras]
    start_time = [None for rtsp in cameras]
    print("Threat detection is running")
    while True:
        frames = read()
        cropped_frames = crop_frames(frames,cameras)
        if len(frames) >= 1:
            t_start_inference = time.time()
            total_inference_time=0
            for i,frame in enumerate(frames):
              if frame is not None:
                frames[i] = cv.cvtColor(frame, cv.COLOR_BGR2RGB)

            if model_path[-4:] == "rknn":
                results,num_detections = perform_inference_on_npu(cropped_frames,model)
            else:
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
                    if len(result[0]) > 0:
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

                        my_table = PrettyTable()
                        my_table.field_names = ["Detection Name","Number of Detections"]
                        detection_dict = {n : 0 for n in detection_classes}

                        detection_dict['Firearm']=len(result[0])
                        for n in detection_classes:
                            my_table.add_row([n, detection_dict[n]])

                        print(my_table)
                        if api_url:
                            if stream_up[i]:
                                print("stream is up")
                                now = time.time()
                                if now-start_time[i] >= 5:
                                    print("Triggering alarm!")
                                    stream_up[i] = validation_request(overlay_image_orig,cameras[i],newId,score)
                                    start_time[i] = time.time()
                                else:
                                    print(f"{now-start_time[i]} seconds have passed")
                                    print("Waiting for 5 seconds to pass")
                            else:
                                print("Triggerring alarm!")
                                stream_up[i] = validation_request(overlay_image_orig,cameras[i],newId,score)
                                start_time[i] = time.time()


        else:
            break
    print('Finished video')

def validation_request(image,camera,id,score):

    try:
        im = cv.imencode('.jpg', image)[1].tobytes()

        if validation_url:
            save_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg", im)
            url = get_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg")
            print(url)
            now = time.time()
            j = {'cameraId': camera['id'], 'imageUrl': url, 'dateTime': str(now), 'imageType': 'weapon', 'bemotionUrl':api_url, 'confidence':score, 'accessKey':api_access_key, 'accessToken':api_secret_key, 'location':location}
            headers = {"detection-access-key": 'asd@#$fdsf4yh(&%$#42dfH%3DfSDvqrt2tg099sdjfsdds_dg_dK_FROSTSCIENCE_DETECTION', "detection-access-token": 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImZyb3N0c2NpZW5jZUBmcm9zdHNjaWVuY2UuY29tIiwibmFtZSI6IkFobWFkIE1hdGthcmkiLCJ1c2VySWQiOjk5OTk5OTk5OTk5LCJub3ciOiIyMDIzLTAxLTAxVDA5OjMwOjMyKzAyOjAwIiwiaXNEZXRlY3Rpb24iOnRydWUsImxhbmd1YWdlSWQiOjF9.6ODrQsWkvp66bcORbMxPYG8car7iGFV1tNEkkitIdNc'}
            res = requests.post(validation_url, json=j, headers=headers)
        elif discourse_username:
            save_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg", im)
            url = get_file(s3, s3_bucket, f"{camera['id']}-image-{id}.jpg")
            now = time.time()
            print("about to make request")
            j = {'raw': camera['id']+" "+str(now)+"\n"+url, 'topic_id': discourse_topic_id, 'category': discourse_category}
            headers = {"Api-Key": api_access_key, "Api-Username": discourse_username}
            res = requests.post(api_url, json=j, headers=headers)
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

def rknn_preprocess(frame):
    frame = cv2.resize(frame, (IMG_SIZE, IMG_SIZE))
    frame = np.expand_dims(frame,0)
    return frame

@hide_warnings
def perform_inference_on_npu(frames,model):
    preds = []
    dets = 0
    for frame in frames:
        frame_preds = []
        if frame is not None:
        # frame2 = cv2.resize(frame, (IMG_SIZE, IMG_SIZE))
        # frame2 = np.expand_dims(frame2,0)
            frame2 = rknn_preprocess(frame)

        # Inference
            outputs = model.inference(inputs=[frame2], data_format=['nhwc'])

        # post process
            input0_data = outputs[0]
            input1_data = outputs[1]
            input2_data = outputs[2]

            input0_data = input0_data.reshape([3, -1]+list(input0_data.shape[-2:]))
            input1_data = input1_data.reshape([3, -1]+list(input1_data.shape[-2:]))
            input2_data = input2_data.reshape([3, -1]+list(input2_data.shape[-2:]))

            input_data = list()
            input_data.append(np.transpose(input0_data, (2, 3, 0, 1)))
            input_data.append(np.transpose(input1_data, (2, 3, 0, 1)))
            input_data.append(np.transpose(input2_data, (2, 3, 0, 1)))

            boxes, classes, scores = yolov5_post_process(input_data,frame)

            if boxes is not None and boxes[0] is not None:
            #print(len(boxes))
                for i,box in enumerate(boxes[0]):
                    if scores[i] >= conf_thresh and classes[i] == 0:
                        dets+=1
                        box = list(box)
                        box.append(scores[i])
                        box.append(classes[i])
                        frame_preds.append(box)
        preds.append(torch.Tensor([frame_preds]))

    return preds,dets

def xywh2xyxy2(x):
    # Convert [x, y, w, h] to [x1, y1, x2, y2]
    y = np.copy(x)
    y[:, 0] = x[:, 0] - x[:, 2] / 2  # top left x
    y[:, 1] = x[:, 1] - x[:, 3] / 2  # top left y
    y[:, 2] = x[:, 0] + x[:, 2] / 2  # bottom right x
    y[:, 3] = x[:, 1] + x[:, 3] / 2  # bottom right y
    return y

def yolov5_post_process(input_data,orig_image):
    masks = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
    anchors = [[10, 13], [16, 30], [33, 23], [30, 61], [62, 45],
               [59, 119], [116, 90], [156, 198], [373, 326]]

    boxes, classes, scores = [], [], []
    for input, mask in zip(input_data, masks):
        b, c, s = process(input, mask, anchors)
        b, c, s = filter_boxes(b, c, s)
        boxes.append(b)
        classes.append(c)
        scores.append(s)

    boxes = np.concatenate(boxes)
    boxes = xywh2xyxy2(boxes)
    classes = np.concatenate(classes)
    scores = np.concatenate(scores)

    nboxes, nclasses, nscores = [], [], []
    for c in set(classes):
        inds = np.where(classes == c)
        b = boxes[inds]
        c = classes[inds]
        s = scores[inds]

        keep = nms_boxes(b, s)

        nboxes.append(b[keep])
        nclasses.append(c[keep])
        nscores.append(s[keep])

    if not nclasses and not nscores:
        return None, None, None

    boxes = np.concatenate(nboxes)
    classes = np.concatenate(nclasses)
    scores = np.concatenate(nscores)

    shape = orig_image.shape[:2]
    new_shape=(IMG_SIZE,IMG_SIZE)
    r = min(new_shape[0]/shape[0],new_shape[1]/shape[1])
    ratio = r,r

    stride=32
    new_unpad = int((shape[1] * r)), int((shape[0] * r))
    dw, dh = new_shape[1] - new_unpad[0], new_shape[0] - new_unpad[1]
    dw /= 2
    dh /= 2
    pad = (dw,dh)
    shapes = (orig_image.shape[0], orig_image.shape[1]), (ratio, pad)
    
    # print(shapes)
    
    boxes = scale_predictions([boxes],(IMG_SIZE,IMG_SIZE),shapes[0],shapes[1])

    return boxes, classes, scores

def sigmoid(x):
    return 1 / (1 + np.exp(-x))

def filter_boxes(boxes, box_confidences, box_class_probs):
    """Filter boxes with box threshold. It's a bit different with origin yolov5 post process!

    # Arguments
        boxes: ndarray, boxes of objects.
        box_confidences: ndarray, confidences of objects.
        box_class_probs: ndarray, class_probs of objects.

    # Returns
        boxes: ndarray, filtered boxes.
        classes: ndarray, classes for boxes.
        scores: ndarray, scores for boxes.
    """
    boxes = boxes.reshape(-1, 4)
    box_confidences = box_confidences.reshape(-1)
    box_class_probs = box_class_probs.reshape(-1, box_class_probs.shape[-1])

    _box_pos = np.where(box_confidences >= OBJ_THRESH)
    boxes = boxes[_box_pos]
    box_confidences = box_confidences[_box_pos]
    box_class_probs = box_class_probs[_box_pos]

    class_max_score = np.max(box_class_probs, axis=-1)
    classes = np.argmax(box_class_probs, axis=-1)
    _class_pos = np.where(class_max_score >= OBJ_THRESH)

    boxes = boxes[_class_pos]
    classes = classes[_class_pos]
    scores = (class_max_score* box_confidences)[_class_pos]

    return boxes, classes, scores

def nms_boxes(boxes, scores):
    """Suppress non-maximal boxes.

    # Arguments
        boxes: ndarray, boxes of objects.
        scores: ndarray, scores of objects.

    # Returns
        keep: ndarray, index of effective boxes.
    """
    x = boxes[:, 0]
    y = boxes[:, 1]
    w = boxes[:, 2] - boxes[:, 0]
    h = boxes[:, 3] - boxes[:, 1]

    areas = w * h
    order = scores.argsort()[::-1]

    keep = []
    while order.size > 0:
        i = order[0]
        keep.append(i)

        xx1 = np.maximum(x[i], x[order[1:]])
        yy1 = np.maximum(y[i], y[order[1:]])
        xx2 = np.minimum(x[i] + w[i], x[order[1:]] + w[order[1:]])
        yy2 = np.minimum(y[i] + h[i], y[order[1:]] + h[order[1:]])

        w1 = np.maximum(0.0, xx2 - xx1 + 0.00001)
        h1 = np.maximum(0.0, yy2 - yy1 + 0.00001)
        inter = w1 * h1

        ovr = inter / (areas[i] + areas[order[1:]] - inter)
        inds = np.where(ovr <= NMS_THRESH)[0]
        order = order[inds + 1]
    keep = np.array(keep)
    return keep

def process(input, mask, anchors):

    anchors = [anchors[i] for i in mask]
    grid_h, grid_w = map(int, input.shape[0:2])

    box_confidence = input[..., 4]
    box_confidence = np.expand_dims(box_confidence, axis=-1)

    box_class_probs = input[..., 5:]

    box_xy = input[..., :2]*2 - 0.5

    col = np.tile(np.arange(0, grid_w), grid_w).reshape(-1, grid_w)
    row = np.tile(np.arange(0, grid_h).reshape(-1, 1), grid_h)
    col = col.reshape(grid_h, grid_w, 1, 1).repeat(3, axis=-2)
    row = row.reshape(grid_h, grid_w, 1, 1).repeat(3, axis=-2)
    grid = np.concatenate((col, row), axis=-1)
    box_xy += grid
    box_xy *= int(IMG_SIZE/grid_h)

    box_wh = pow(input[..., 2:4]*2, 2)
    box_wh = box_wh * anchors

    box = np.concatenate((box_xy, box_wh), axis=-1)

    return box, box_confidence, box_class_probs

def filter(predictions,frame,camera):
    filtered_predictions = []
    intersecting_preds = []
    final_preds = []
    scores = []
    if frame is not None:
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
         #       if ratio < camera['max_percentage'] and ratio != 0.0:
                if ratio < 0.1 and ratio != 0.0:

                    detected_object = detected_object.tolist()
                    filtered_predictions.append(detected_object[i])
                    scores.append(score)
                    detected_object = torch.Tensor(detected_object)
#        return torch.Tensor(filtered_predictions),len(filtered_predictions)
 
def filter(predictions,frame,camera):
    filtered_predictions = []
    intersecting_preds = []
    people_preds = []
    final_preds = []
    scores = []
    if frame is not None:
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
         #       if ratio < camera['max_percentage'] and ratio != 0.0:
                if ratio < 0.1 and ratio != 0.0:

                    detected_object = detected_object.tolist()
                    filtered_predictions.append(detected_object[i])
                    scores.append(score)
                    detected_object = torch.Tensor(detected_object)
#        return torch.Tensor(filtered_predictions),len(filtered_predictions)
 
        if len(filtered_predictions):
            people_results,num_detections = perform_inference_on_npu([frame],people_model)
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
                                    people_preds.append(res[i])
    for pred in intersecting_preds:
        height = pred[3]-pred[1]
        width = pred[2]-pred[0]
        #print(pred)
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
        results,num_detections = perform_inference_on_npu([crop_frame],model)

        if num_detections > 0:
            for object in intersecting_preds:
                final_preds.append(object)
            return torch.Tensor(final_preds),len(final_preds)
    for pred in people_preds:
        height = pred[3]-pred[1]
        width = pred[2]-pred[0]
        #print(pred)
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
        results,num_detections = perform_inference_on_npu([crop_frame],model)

        if num_detections > 0:
            for object in intersecting_preds:
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

NMS_THRESH = 0.6
IMG_SIZE = 640
OBJ_THRESH = 0.4

if model_path[-4:] == "rknn":
    model = RKNNLite(verbose=False) # successful
    ret = model.load_rknn(model_path) # successful
    #if model != 0:
    #    print('Load RKNN model failed')
    #    exit(model)
    ret = model.init_runtime(core_mask=RKNNLite.NPU_CORE_0)
    #  ret = model.init_runtime()
    people_model = RKNNLite(verbose=False)
    p_ret = people_model.load_rknn("./yolov5s-640-640.rknn")
    p_ret = people_model.init_runtime(core_mask=RKNNLite.NPU_CORE_0)
#    gun_frame = cv2.imread("./people.jpg")
#    _,num_detections = perform_inference_on_npu([gun_frame],people_model)
#    print(str(num_detections) + " guns")
#    input("Continue?")
else:

    model = torch.hub.load('./ultralytics/yolov5', 'custom', path=model_path, source="local")
    model.conf = conf_thresh
    model.iou = iou_thresh
    model.classes = [80]

    people_model = torch.hub.load('./ultralytics/yolov5', 'custom', path='./models/yolov5n.pt', source="local")
    people_model.conf = 0.4
    people_model.iou = iou_thresh
    people_model.classes = [0]

while True:
    dims = [get_video_size(camera['rtsp']) for camera in cameras]
    run_inference_for_video()
