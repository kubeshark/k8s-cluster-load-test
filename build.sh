#!/bin/sh

# Set the version number as a variable
VERSION="v52.3.88"

# Navigate to the certs directory and generate certificates
cd certs
./generate.sh

# Build and push the Nginx server image
cd ../nginx
docker buildx build --platform linux/amd64,linux/arm64 -t kubeshark/k6s-load-server:$VERSION . --push

# Build and push the k6 load test image
cd ../k6
docker buildx build --platform linux/amd64,linux/arm64 -t kubeshark/k6s-load-test:$VERSION . --push

# Build and push the Go HTTP/2 client image
cd ../go-http2-client  # Navigate to the directory containing the Go application and Dockerfile
make build
docker buildx build --platform linux/amd64,linux/arm64 -t kubeshark/go-http2-client:$VERSION . --push

# Build and push the Go HTTP/2 server image
cd ../go-http2-server  # Navigate to the directory containing the Go application and Dockerfile
make build
docker buildx build --platform linux/amd64,linux/arm64 -t kubeshark/go-http2-server:$VERSION . --push
