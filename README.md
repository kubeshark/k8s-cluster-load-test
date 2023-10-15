# Configurable Kubernetes Cluster Load Test

This repository is useful for conducting load tests on your Kubernetes cluster.

## TL;DR

If you want to launch an application consisting of 5 server pods and 10 client pods, where each client runs 50 parallel downloads of a small file with no rate limit and no delay between downloads, use [this manifest](load-test.yaml).

## Properties

- FILE_SIZE: "SMALL"          # Use either SMALL (~12KB) or LARGE (~500KB)
- DELAY: "0"                  # Delay between consecutive downloads
- RATE_LIMIT: "500k"          # Download rate limit
- PARALLEL_DOWNLOADS: "50"    # Number of parallel downloads per client container

## Architecture

The load test is composed of two sets of either client or server pods:

- N * curl-client
- M * httpd-server

A total of M+N pods are launched, where N is the number of curl-client replicas, and M is the number of httpd-server replicas. Both replica numbers can be configured in the `load-test.yaml` manifest.

Each curl-client executes multiple loops of file downloads using the CURL command. The number of parallel loops, the loop delay, the file size, and the rate limitation are all determined by the properties mentioned above.

## Use Cases

### Test Throughput

- Choose the SMALL file to stress the throughput.
- Use the DELAY property to reduce the throughput.

### Test Bandwidth

- Choose the large file to stress the bandwidth.
- Use RATE_LIMIT to throttle the download rate.

### Control the Number of Pods

- Use the server and client replica numbers to control the number of pods.

### Scale Up and Down

Use the following commands to scale up and down the number of server and client pods:

```shell
kubectl scale deployment httpd-server --replicas=10 -n ks-load
kubectl scale deployment curl-client --replicas=100 -n ks-load
```

### Controlling the Load

- You can increase the load by adjusting the `PARALLEL_DOWNLOADS` property to make each client initiate multiple parallel downloads.

## How to Run

Optionally, modify its properties and apply the [load-test.yaml](load-test.yaml) manifest:

```shell
kubectl apply -f load-test.yaml
```
## View outcome with Kubeshark

Run the following command:
```shell
kubeshark tap -n ks-load
```
And see the results:
<img width="1448" alt="image" src="https://github.com/kubeshark/k8s-cluster-load-test/assets/1990761/a0601dd5-f99a-41dd-ac5b-9f0cc5b0e0b3">


