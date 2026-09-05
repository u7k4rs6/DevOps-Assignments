#!/bin/bash
# Build and run the Java app. Container port 8080 -> host port 8082
# (8080 on the host is already taken by the multi-stage app).
set -e
docker build -t java-hello .
docker rm -f java-container 2>/dev/null || true
docker run -d --name java-container -p 8082:8080 java-hello
sleep 3
curl -s http://localhost:8082
