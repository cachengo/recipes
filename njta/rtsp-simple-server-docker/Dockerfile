# Copyright 2019, Cachengo, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.




FROM ubuntu:18.04
RUN apt update && apt install -y supervisor ffmpeg

WORKDIR /app
COPY rtsp-simple-server ./rtsp-simple-server
#RUN sed -i "s/#RTSP_URL#/$RTSP_URL/g" rtsp-simple_server.yml
COPY rtsp-simple-server.yml ./rtsp-simple-server.yml

COPY supervisord.conf /etc/supervisord.conf

CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
