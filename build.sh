#!/bin/sh
cd certs
./generate.sh
cd ../nginx
docker buildx build --platform linux/amd64 -t kubeshark/mert-k6s-load-server:latest . --push
cd ../k6
docker buildx build --platform linux/amd64 -t kubeshark/mert-k6s-load-test:latest . --push
