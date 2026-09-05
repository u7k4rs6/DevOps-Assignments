#!/bin/bash
# Build and run the Node.js app on host port 3000
set -e
docker build -t nodejs-hello .
docker rm -f nodejs-container 2>/dev/null || true
docker run -d --name nodejs-container -p 3000:3000 nodejs-hello
sleep 2
curl -s http://localhost:3000
