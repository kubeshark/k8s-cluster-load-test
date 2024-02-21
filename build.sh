#!/bin/sh
cd certs
./generate.sh
cd ../nginx
docker buildx build --platform linux/amd64 -t alongir/ks-load-server:latest . --push 
cd ../k6
docker buildx build --platform linux/amd64 -t alongir/k6-loadtest:latest . --push 