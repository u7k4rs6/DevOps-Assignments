#!/bin/bash
# Build and run the Apache static site. Container port 80 -> host port 8083.
set -e
docker build -t apache-hello .
docker rm -f apache-container 2>/dev/null || true
docker run -d --name apache-container -p 8083:80 apache-hello
sleep 2
curl -s http://localhost:8083
