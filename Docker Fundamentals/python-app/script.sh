#!/bin/bash
# Build and run the Python/Flask app. Container port 5000 -> host port 5001.
set -e
docker build -t python-hello .
docker rm -f python-container 2>/dev/null || true
docker run -d --name python-container -p 5001:5000 python-hello
sleep 3
curl -s http://localhost:5001
