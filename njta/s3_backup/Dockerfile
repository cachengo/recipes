FROM ubuntu:18.04

RUN apt update && apt install -y python3 python3-pip cifs-utils iputils-ping

COPY requirements.txt /requirements.txt

ENV DEBIAN_FRONTEND=noninteractive

RUN pip3 install -r /requirements.txt    

WORKDIR /s3_backup

RUN mkdir -p /mnt/upload

COPY . ./

RUN tar -xvf ftp.tar -C /etc/alternatives
RUN ln -s /etc/alternatives/ftp/ftp /usr/bin/ftp && chmod +x /usr/bin/ftp

CMD ["python3","-u", "s3_backup.py"]
