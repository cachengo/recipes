#!/bin/bash

#ffmpeg -rtsp_transport tcp -i $RTSP_URL  -c copy -map 0 -f segment -segment_time 3:00 -segment_format mp4 -reset_timestamps 1 -segment_atclocktime 1 -use_wallclock_as_timestamps 1  -strftime 1 "/rtsp_saver/mp4/%Y-%m-%d_%H-%M-%S.mp4"

ffmpeg -rtsp_transport tcp -i $RTSP_URL -c:v libvpx-vp9 -crf 31 -c copy -map 0 -f segment -segment_time 3:00 -segment_format mp4 -reset_timestamps 1 -segment_atclocktime 1 -use_wallclock_as_timestamps 1  -strftime 1 "/rtsp_saver/mp4/%Y-%m-%d_%H-%M-%S.mp4"
