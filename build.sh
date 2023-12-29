#!/bin/sh
cd httpd
docker buildx build --platform linux/amd64 -t alongir/ks-load-httpd:latest . --push 
cd ../k6
docker buildx build --platform linux/amd64 -t alongir/k6-loadtest:latest . --push 