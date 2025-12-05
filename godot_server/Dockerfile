FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3 python3-pip curl
WORKDIR /app
COPY ./export /export
COPY placeholder_ws.py /app/placeholder_ws.py
CMD if [ -f /export/isleborn_server.x86_64 ]; then chmod +x /export/isleborn_server.x86_64; /export/isleborn_server.x86_64 --server --headless; else echo 'No Godot binary found in /export. Running placeholder WS server.'; python3 /app/placeholder_ws.py; fi
