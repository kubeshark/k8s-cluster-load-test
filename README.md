# Configurable Kubernetes Cluster Load Test

This repository is useful for conducting load tests on your Kubernetes cluster.

## Architecture

The load test is composed of two sets of either client or server pods:

- N * k6-load-test
- M * httpd-service

A total of M+N pods are launched, where N is the number of k6-load-test replicas, and M is the number of httpd-service replicas. Both replica numbers can be configured in the `load-test.yaml` manifest.

## Configuration

```yaml
    spec:
      containers:
      - name: k6
        image: alongir/k6-loadtest:latest
        env:
          - name: VUS       # concurrency level
            value: "300"
          - name: DURATION  # duration of keeping the load after a 20s ramp up
            value: "3h"
          - name: URL       # The URL to download
            value: "http://httpd-service.ks-load.svc.cluster.local/smap.png"
          - name: SLEEP     # Wait time between downloads
            value: "0"
```
## Available Files to Download

505742B - http://httpd-service.ks-load.svc.cluster.local/smap.png

1024B   - http://httpd-service.ks-load.svc.cluster.local/1k.png

12164B   - http://httpd-service.ks-load.svc.cluster.local/ks_logo.png

## Replicas
Adjust the `replicas` fields for both deployments to control the number of server and client instances.

## Start

```shell
kubectl apply -f load-test.yaml
```

## Stop

```shell
kubectl delete -f load-test.yaml
```
