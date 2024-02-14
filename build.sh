#!/bin/sh
cd certs
./generate.sh
cd ../caddy
docker buildx build --platform linux/amd64 -t alongir/ks-load-caddy:latest . --push 
cd ../k6
docker buildx build --platform linux/amd64 -t alongir/k6-loadtest:latest . --push 