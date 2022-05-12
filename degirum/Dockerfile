FROM ubuntu:20.04

RUN mkdir /zoo \
&& cd /zoo \
&& python3 -m pip install degirum --extra-index-url https://degirum.github.io/simple \
&& python3 -c "from degirum import server; server.download_models('.')" \
&& python3 -m degirum.server --zoo /zoo

WORKDIR /

EXPOSE 8778

ENTRYPOINT ["./boot.sh"]
