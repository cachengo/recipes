FROM ubuntu:18.04

RUN apt update && apt install -y python3 python3-pip supervisor ffmpeg

COPY requirements.txt /requirements.txt

ENV DEBIAN_FRONTEND=noninteractive

RUN pip3 install -r /requirements.txt    

WORKDIR /rtsp_saver

RUN mkdir /rtsp_saver/mp4

COPY . ./
COPY supervisord.conf /etc/supervisord/supervisord.conf
COPY run_ffmpeg.sh /rtsp_saver/run_ffmpeg.sh

CMD ["supervisord", "-n", "-c", "/etc/supervisord/supervisord.conf"]
