import torch
import torchvision
import cv2
import numpy as np
from PIL import Image
import time
from bbox_utils import xywh2xyxy, xyxy2xywh,letterbox, to_numpy, scale_predictions
import json

def non_max_suppression(prediction, conf_thres=0.25, iou_thres=0.45, classes=None, agnostic=False, multi_label=False,
                        labels=(), max_det=300):
    """Runs Non-Maximum Suppression (NMS) on inference results
    Returns:
         list of detections, on (n,6) tensor per image [xyxy, conf, cls]
    """

    nc = prediction.shape[2] - 5  # number of classes
    xc = prediction[..., 4] > conf_thres  # candidates

    # Checks
    assert 0 <= conf_thres <= 1, f'Invalid Confidence threshold {conf_thres}, valid values are between 0.0 and 1.0'
    assert 0 <= iou_thres <= 1, f'Invalid IoU {iou_thres}, valid values are between 0.0 and 1.0'

    # Settings
    min_wh, max_wh = 2, 4096  # (pixels) minimum and maximum box width and height
    max_nms = 30000  # maximum number of boxes into torchvision.ops.nms()
    time_limit = 10.0  # seconds to quit after
    redundant = True  # require redundant detections
    multi_label &= nc > 1  # multiple labels per box (adds 0.5ms/img)
    merge = False  # use merge-NMS

    t = time.time()
    output = [torch.zeros((0, 6), device=prediction.device)] * prediction.shape[0]
    for xi, x in enumerate(prediction):  # image index, image inference
        # Apply constraints
        # x[((x[..., 2:4] < min_wh) | (x[..., 2:4] > max_wh)).any(1), 4] = 0  # width-height
        x = x[xc[xi]]  # confidence

        # Cat apriori labels if autolabelling
        if labels and len(labels[xi]):
            l = labels[xi]
            v = torch.zeros((len(l), nc + 5), device=x.device)
            v[:, :4] = l[:, 1:5]  # box
            v[:, 4] = 1.0  # conf
            v[range(len(l)), l[:, 0].long() + 5] = 1.0  # cls
            x = torch.cat((x, v), 0)

        # If none remain process next image
        if not x.shape[0]:
            continue

        # Compute conf
        x[:, 5:] *= x[:, 4:5]  # conf = obj_conf * cls_conf

        # Box (center x, center y, width, height) to (x1, y1, x2, y2)
        box = xywh2xyxy(x[:, :4])

        # Detections matrix nx6 (xyxy, conf, cls)
        if multi_label:
            i, j = (x[:, 5:] > conf_thres).nonzero(as_tuple=False).T
            x = torch.cat((box[i], x[i, j + 5, None], j[:, None].float()), 1)
        else:  # best class only
            conf, j = x[:, 5:].max(1, keepdim=True)
            x = torch.cat((box, conf, j.float()), 1)[conf.view(-1) > conf_thres]

        # Filter by class
        if classes is not None:
            x = x[(x[:, 5:6] == torch.tensor(classes, device=x.device)).any(1)]

        # Apply finite constraint
        # if not torch.isfinite(x).all():
        #     x = x[torch.isfinite(x).all(1)]

        # Check shape
        n = x.shape[0]  # number of boxes
        if not n:  # no boxes
            continue
        elif n > max_nms:  # excess boxes
            x = x[x[:, 4].argsort(descending=True)[:max_nms]]  # sort by confidence

        # Batched NMS
        c = x[:, 5:6] * (0 if agnostic else max_wh)  # classes
        boxes, scores = x[:, :4] + c, x[:, 4]  # boxes (offset by class), scores
        i = torchvision.ops.nms(boxes, scores, iou_thres)  # NMS
        if i.shape[0] > max_det:  # limit detections
            i = i[:max_det]
        if merge and (1 < n < 3E3):  # Merge NMS (boxes merged using weighted mean)
            # update boxes as boxes(i,4) = weights(i,n) * boxes(n,4)
            iou = box_iou(boxes[i], boxes) > iou_thres  # iou matrix
            weights = iou * scores[None]  # box weights
            x[i, :4] = torch.mm(weights, x[:, :4]).float() / weights.sum(1, keepdim=True)  # merged boxes
            if redundant:
                i = i[iou.sum(1) > 1]  # require redundancy

        output[xi] = x[i]
        if (time.time() - t) > time_limit:
            print(f'WARNING: NMS time limit {time_limit}s exceeded')
            break  # time limit exceeded

    return output

def make_pytorch_grid(device,anchors,stride,na, nx=20, ny=20, i=0):
    d = anchors.device
    yv, xv = torch.meshgrid([torch.arange(ny).to(d), torch.arange(nx).to(d)])
    grid = torch.stack((xv, yv), 2).expand((1, na, ny, nx, 2)).float()
    anchor_grid = (anchors[i].clone() * stride[i]) \
        .view((1, na, 1, 1, 2)).expand((1, na, ny, nx, 2)).float()
    return grid, anchor_grid



def save_one_json(predn, jdict, path, class_map):
    # Save one JSON result {"image_id": 42, "category_id": 18, "bbox": [258.15, 41.29, 348.26, 243.78], "score": 0.236}
    image_id = int(path.stem) if path.stem.isnumeric() else path.stem
    box = xyxy2xywh(predn[:, :4])  # xywh
    box[:, :2] -= box[:, 2:] / 2  # xy center to top-left corner
    for p, b in zip(predn.tolist(), box.tolist()):
        jdict.append({'image_id': image_id,
                      'category_id': class_map[int(p[5])],
                      'bbox': [round(x, 3) for x in b],
                      'score': round(p[4], 5)})
        
def save_one_json(predn, jdict, image_id, class_map):
    # Save one JSON result {"image_id": 42, "category_id": 18, "bbox": [258.15, 41.29, 348.26, 243.78], "score": 0.236}
    #image_id = int(path.stem) if path.stem.isnumeric() else path.stem
    box = xyxy2xywh(predn[:, :4])  # xywh
    box[:, :2] -= box[:, 2:] / 2  # xy center to top-left corner
    for p, b in zip(predn.tolist(), box.tolist()):
        jdict.append({'image_id': image_id,
                      'category_id': class_map[int(p[5])],
                      'bbox': [round(x, 3) for x in b],
                      'score': round(p[4], 5)})



def get_yolov5_anchors(device,image_size,num_classes):
    anchors=np.asarray([  [10,13, 16,30, 33,23],
                          [30,61, 62,45, 59,119],
                          [116,90, 156,198, 373,326] 
                        ])
    nc=num_classes
    no=nc+5
    nl = len(anchors)  # number of detection layers
    na = len(anchors[0]) // 2  # number of anchors
    grid = [torch.zeros(1)] * nl
    anchor_grid = [torch.zeros(1)] * nl
    xy_mul = [torch.zeros(1)] * nl
    scaled_grid = [torch.zeros(1)] * nl
    stride=np.asarray([8,16,32])
    stride_broadcast=np.transpose(np.broadcast_to(stride,(6,3)))
    anchors_scaled=anchors/stride_broadcast
    stride_torch = torch.tensor(np.asarray(stride), dtype=torch.float32)
    anchors_torch = torch.tensor(np.asarray(anchors_scaled), dtype=torch.float32)
    for index, nx in enumerate(image_size//stride):
        grid[index],anchor_grid[index]=make_pytorch_grid(device,anchors_torch,stride_torch,na, nx, nx, index)
        grid[index] =grid[index].permute(0, 2, 3, 1, 4).contiguous()
        anchor_grid[index]=anchor_grid[index].permute(0, 2, 3, 1, 4).contiguous()
        grid[index]=grid[index].reshape(-1,2)
        scaled_grid[index]=grid[index]*stride[index]
        xy_mul[index]=torch.tensor(np.broadcast_to(stride[index],(na*nx*nx)))
        anchor_grid[index]=anchor_grid[index].reshape(-1,2)
    grid_concat=torch.cat(scaled_grid, 0)
    anchor_grid_concat=torch.cat(anchor_grid, 0)
    xy_mul_concat=torch.cat(xy_mul,0)
    return grid_concat,anchor_grid_concat,xy_mul_concat

def preprocess_yolov5(filepath,image_size):
    #orig_img = np.asarray((Image.open(str(filepath))).convert('RGB'))
    orig_img=np.asarray(cv2.imread(filepath))[::,::,::-1]
    letterbox_img,ratio, pad=letterbox(orig_img,new_shape=(image_size, image_size),auto=False, scaleFill=False,scaleup=False,stride=32)
    shapes = (orig_img.shape[0], orig_img.shape[1]), (ratio, pad) 
    img_array = np.expand_dims(np.array(letterbox_img), axis=0).astype(np.float32)
    img_array2=(img_array)/255
    torch_image=torch.tensor(img_array2)
    input_array=torch.cat([torch_image[..., ::2, ::2,:], torch_image[..., 1::2, ::2,:], torch_image[..., ::2, 1::2,:], torch_image[..., 1::2, 1::2,:]], 3)
    input_array=to_numpy(input_array)
    return orig_img,input_array,letterbox_img,shapes

def preprocess_yolov5_video(filepath,image_size):
    #orig_img = np.asarray((Image.open(str(filepath))).convert('RGB'))
    #orig_img=np.asarray(cv2.imread(filepath))[::,::,::-1]
    orig_img=filepath
    letterbox_img,ratio, pad=letterbox(orig_img,new_shape=(image_size, image_size),auto=False, scaleFill=False,scaleup=False,stride=32)
    shapes = (orig_img.shape[0], orig_img.shape[1]), (ratio, pad) 
    img_array = np.expand_dims(np.array(letterbox_img), axis=0).astype(np.float32)
    img_array2=(img_array)/255
    torch_image=torch.tensor(img_array2)
    input_array=torch.cat([torch_image[..., ::2, ::2,:], torch_image[..., 1::2, ::2,:], torch_image[..., ::2, 1::2,:], torch_image[..., 1::2, 1::2,:]], 3)
    input_array=to_numpy(input_array)
    return orig_img,input_array,letterbox_img,shapes

def postprocess_yolov5_output(model_output,num_classes,grid_concat,anchor_grid_concat,xy_mul_concat):
    no=num_classes+5
    full_output=[]
    for index, output_tensor in enumerate(model_output):
        output_tensor = torch.tensor(output_tensor)
        full_output.append(output_tensor.view(1,-1,no))
    full_output=torch.cat(full_output, 1)
    out_data=torch.sigmoid(full_output)
    out_data[..., 0] = (out_data[..., 0] * 2. - 0.5)*xy_mul_concat + grid_concat[...,0]
    out_data[..., 1] = (out_data[..., 1] * 2. - 0.5)*xy_mul_concat + grid_concat[...,1]
    out_data[..., 2] = (out_data[..., 2] * 2) ** 2 * anchor_grid_concat[...,0] 
    out_data[..., 3] = (out_data[..., 3] * 2) ** 2 * anchor_grid_concat[...,1] 
    return out_data

def get_predictions_json(image_folder_path,files_dict,pred_json,model,image_size,num_classes,grid_concat,anchor_grid_concat,xy_mul_concat, class_map,conf_thres=0.001, iou_thres=0.6,print_interval=50):
    jdict=[]
    for index, file in enumerate(files_dict):
        filepath=image_folder_path+file['file_name']
        #print(filepath)
        image_id=file['id']
        orig_img_array,input_img_array,letterbox_img,shapes=preprocess_yolov5(str(filepath),image_size)
        raw_output_data=model.predict(input_img_array)
        output_array=postprocess_yolov5_output(raw_output_data,num_classes,grid_concat,anchor_grid_concat,xy_mul_concat)
        predictions=non_max_suppression(output_array, conf_thres=conf_thres, iou_thres=iou_thres, classes=None, agnostic=False,multi_label=True, labels=(), max_det=300)
        scaled_predictions=scale_predictions(predictions,(image_size,image_size),shapes[0],shapes[1])
        for prediction in scaled_predictions:
            save_one_json(prediction, jdict, image_id, class_map)
        if(print_interval):
            if index%print_interval==print_interval-1:
                print('predicted',index,' images')
    with open(pred_json, 'w') as f:
        json.dump(jdict, f)
    
