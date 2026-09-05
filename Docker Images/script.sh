#!/bin/bash
# Build and run the multi-stage app on host port 8080,
# then build the single-stage twin so the sizes can be compared.
set -e

docker build -t multi-stage-hello .
docker build -f Dockerfile.single-stage -t single-stage-hello .

docker rm -f multi-stage-container 2>/dev/null || true
docker run -d --name multi-stage-container -p 8080:8080 multi-stage-hello

sleep 2
curl -s http://localhost:8080
echo
docker images multi-stage-hello single-stage-hello
