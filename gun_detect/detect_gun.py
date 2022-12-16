#!/usr/bin/env python3.8

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
import sys
import os
os.environ['OPENCV_LOG_LEVEL'] = 'OFF'
os.environ['NUMPY_LOG_LEVEL'] = 'OFF'
os.environ['OPENCV_FFMPEG_DEBUG'] = 'OFF'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import numpy as np
import tflite_runtime.interpreter as tf
from bbox_utils import scale_predictions, overlay_boxes
from yolov5_utils import *
from PIL import Image, ImageDraw
import numpy as np
import time
import cv2 as cv
import matplotlib.pyplot as plt
import queue, threading
import multiprocessing
from prettytable import PrettyTable
import sys
import argparse
from datetime import datetime
from threading import Thread
import requests

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--image')
parser.add_argument('-v', '--video')
parser.add_argument('-l', '--location')
parser.add_argument('-c', '--id')
parser.add_argument('-t', '--send_to')
parser.add_argument('-f', '--send_from')
parser.add_argument('-p', '--password')
options = parser.parse_args()

detection_classes = ['gun']
if options.image:
    filepath = options.image
elif options.video:
    filepath = options.video
if options.location:
    location = options.location
if options.id:
    camera_id = options.id
    while True:
        try:
            response = requests.get('http://localhost:8080/api/process', headers = {'join-secret':'cachengo'})
            break
        except requests.exceptions.RequestException as e:
            print(f'Failed to get rtsp stream for camera id {camera_id} from argos')

    filepath = response.json()['Processes'][camera_id]['command'].split(" ")[5]

if options.send_from:
   sender = options.send_from
if options.send_to:
   receiver = options.send_to
if options.password:
   password = options.password


def check_remote_up(ip):
    response = os.system(f'ping -c 1 {ip}')
    return response == 0

def run_inference_for_image(filepath,model,conf_thresh):
    orig_img,results = perform_inference_on_single_image(model,filepath,conf_thresh)
    overlay_image_orig = overlay_boxes(orig_img,results)
    im = overlay_image_orig.save("tmp.jpg")
    now = datetime.now()
    dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
    my_table = PrettyTable()
    my_table.field_names = ["Detection Name","Number of Detections"]
    detection_dict = {i : 0 for i in detection_classes}
    for idx, box in enumerate(results[0]):
        if len(results[0]) >= 1:
            thread = Thread(target=send_email, args=("Cachengo Detection Event", sender, receiver, password, "./tmp.jpg", "Gun Detected!", dt_string, camera_id, location))
            thread.start()
            detection = int(results[0][idx][-1].item())
            class_name = detection_classes[detection]
            detection_dict[class_name]+=1
    for i in detection_classes:
        my_table.add_row([i, detection_dict[i]])

    print(my_table)

def run_inference_for_video(video_path,model,conf_thresh):
        cap = cv.VideoCapture(video_path)
        cap.set(cv.CAP_PROP_BUFFERSIZE, 0)
        threads = []
        frame_num = -1
        count=0
        stream_up = False
        start_time = None
        while cap.isOpened():
            count+=1
            ret, frame = cap.read()
            if count%60!=0:
                continue
            if ret:
                frame_num += 1
                t_start_inference = time.time()
                total_inference_time=0
                orig_img,results = perform_inference_on_single_image(model,frame,conf_thresh)
                overlay_image_orig = overlay_boxes(orig_img,results)
                cv_image = np.asarray(overlay_image_orig)[:,:,::-1]
                im = overlay_image_orig.save("/data/models/tmp.jpg")
                my_table = PrettyTable()
                my_table.field_names = ["Detection Name","Number of Detections"]
                detection_dict = {i : 0 for i in detection_classes}
                for idx, box in enumerate(results[0]):
                    if len(results[0]) >= 1:
                        detection = int(results[0][idx][-1].item())
                        class_name = detection_classes[detection]
                        detection_dict[class_name]+=1
                for i in detection_classes:
                    my_table.add_row([i, detection_dict[i]])
                now = datetime.now()
                dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

                total_inference_time += time.time() - t_start_inference
                if len(threads) > 0:
                    threads = [t for t in threads if t.is_alive()]
                if len(results[0]) >= 1:
                    print(dt_string)
                    print(my_table)
                    if stream_up:
                        now = time.time()
                        if now-start_time >= 3600:
                            while not check_remote_up('8.8.8.8'):
                                print("Waiting for internet connection")
                            while True:
                                try:
                                    response = requests.get(f'http://localhost:8080/live/{camera_id}', headers={'join-secret':'cachengo'})
                                    start_time = time.perf_counter()
                                    break
                                except requests.exceptions.RequestException as e:
                                    print(f'Failed to trigger live stream for {camera_id}')
                                    stream_up=False
                    else:
                        while not check_remote_up('8.8.8.8'):
                            print("Waiting for internet connection")
                        while True:
                            try:
                                response = requests.get(f'http://localhost:8080/live/{camera_id}', headers={'join-secret':'cachengo'})
                                stream_up = True
                                start_time = time.time()
                                break
                            except requests.exceptions.RequestException as e:
                                print(f'Failed to trigger live stream for {camera_id}')
                                stream_up = False


                    now = datetime.now()
                    dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
                    thread = Thread(target=send_email, args=("Event Detected", sender, receiver, password, "/data/models/tmp.jpg", "Gun Detected!", dt_string, camera_id, location))
                    thread.start()
                    threads.append(thread)
            else:
                break
        print('Finished video')

def resize_image(im, desired_size, channels, stretch=False):
    old_size = im.shape[:2] # old_size is in (height, width) format
    if old_size[0] == desired_size and old_size[1] == desired_size:
        return im, (0, 0)

    if stretch:
        return cv.resize(im, (desired_size, desired_size)), (1, 1)

    ratio = float(desired_size)/max(old_size)
    new_size = tuple([int(x*ratio) for x in old_size])

    im = cv.resize(im, (new_size[1], new_size[0]))

    delta_w = desired_size - new_size[1]
    delta_h = desired_size - new_size[0]
    top, bottom = delta_h//2, delta_h-(delta_h//2)
    left, right = delta_w//2, delta_w-(delta_w//2)

    color = [0, 0, 0]
    new_im = cv.copyMakeBorder(im, top, bottom, left, right, cv.BORDER_CONSTANT, value=color)
    (B, G, R) = cv.split(new_im)
    if channels == 2:
         channel_arr = [G,R]
         new_im = cv.merge(channel_arr)
    if channels == 1:
         new_im = R
    return new_im, (delta_w/desired_size, delta_h/desired_size)

def import_model(model_path):
    interpreter = tf.Interpreter(
    model_path=model_path,
    experimental_delegates=[armnn_delegate]
    )
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    return interpreter, input_details, output_details

def perform_inference_on_single_image(interpreter,filepath,conf_thresh):
    if options.image:
        orig_img,input_array,letterbox_img,shapes=preprocess_yolov5(filepath,image_size)
        image = Image.open(filepath)
        input_array2 = np.asarray(image)
        input_data,border_sizes = resize_image(input_array2, 512, 3)
        input_data = (input_data/255).astype('float32')
        input_array = np.expand_dims(input_data, axis=0)
    else:
        orig_img,input_array,letterbox_img,shapes=preprocess_yolov5_video(filepath,image_size)
        input_data,border_sizes = resize_image(filepath, 512, 3)
        input_data = (input_data/255).astype('float32')
        input_array = np.expand_dims(input_data, axis=0)

    interpreter.set_tensor(input_details[0]['index'], input_array)
    start = time.time()
    interpreter.invoke()
    end = time.time()-start
    print("Inference took: "+str(end))
    output_data = interpreter.get_tensor(output_details[0]['index'])
    output_array=postprocess_yolov5_output(output_data,num_classes,grid_concat,anchor_grid_concat,xy_mul_concat)
    predictions=non_max_suppression(output_array, conf_thres=conf_thresh, iou_thres=iou_thresh, classes=None, agnostic=class_agnostic_nms, multi_label=False,
                       labels=(), max_det=maximum_detections)
    scaled_predictions=scale_predictions(predictions,(image_size,image_size),shapes[0],shapes[1])
    return orig_img,scaled_predictions

def send_email(subject, from_addr, to_addr, password, image_path, message, date, stream, location):

    msg = MIMEMultipart('alternative')
    msg['Subject'] = subject
    msg['From'] = from_addr
    msg['To'] = to_addr

    text = MIMEText(f'<p style="text-align:center;"><img src="cid:logo" alt="Logo"></p><br><p style="margin:0">Date: {date}</p><br><p style="margin:0">Event: Gun</p><p style="margin:0">Location: {location}</p><p style="margin:0">Live Stream: <a href="https://live.cachengo.com:8888/{stream}/">https://live.cachengo.com:8888/{stream}/</p><br><p>Greetings, <br>A weapon was detected by one of your cameras.<a href="https://live.cachengo.com:8888/{stream}/">Click here to view the live stream!</p><br><p style="text-align:center;"><img src="cid:image1" width="60%" alt="image"></p>', 'html')

    msg.attach(text)
    logo = MIMEImage(open("/data/models/cachengo.png", 'rb').read())
    image = MIMEImage(open(image_path, 'rb').read())

    image.add_header('Content-ID', '<image1>')
    logo.add_header('Content-ID', '<logo>')

    msg.attach(image)
    msg.attach(logo)

    s = smtplib.SMTP_SSL('smtp.gmail.com')
    s.login(from_addr, password)
    s.sendmail(from_addr, to_addr, msg.as_string())
    s.quit()
    os.remove(image_path)


image_size=512
num_classes=1
device='cpu'
conf_thresh=0.8
iou_thresh=0.6
class_agnostic_nms=True
maximum_detections=100
grid_concat,anchor_grid_concat,xy_mul_concat=get_yolov5_anchors(device,image_size,num_classes)

armnn_delegate = tf.load_delegate(
    library="/armnn/build/delegate/libarmnnDelegate.so",
    options={"backends": "CpuAcc,GpuAcc,CpuRef", "logging-severity":"info"}
)

model, input_details, output_details=import_model("/data/models/yolov5s_relu6_gun-fp32.tflite")
f= open ('/data/models/logo.txt','r')
print(''.join([line for line in f]))
if options.image:
    run_inference_for_image(filepath,model,conf_thresh)
else:
    while True:
        run_inference_for_video(filepath,model,conf_thresh)
