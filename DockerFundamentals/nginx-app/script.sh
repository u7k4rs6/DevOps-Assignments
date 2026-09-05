#!/bin/bash
# Build and run the Nginx static site. Container port 80 -> host port 8081.
set -e
docker build -t nginx-hello .
docker rm -f nginx-container 2>/dev/null || true
docker run -d --name nginx-container -p 8081:80 nginx-hello
sleep 2
curl -s http://localhost:8081
