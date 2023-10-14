# Configurable K8s Cluster Load Test
This repo is useful in cases you'd like to load test your Kubernetes cluster.

## TL;DR

Let's assume you want to launch an application that includes 5 server pods, 10 client pods, where each client runs 50 parallel downloads of a small file with no rate limit and no delay between downloads, use this [this manifest](load-test.yaml).
 
## Properties

- FILE_SIZE: "SMALL"          # use either SMALL (~12KB) or LARGE (~500KB)
- DELAY: "0"                  # Delay between consecutive downloads.
- RATE_LIMIT: "500k"          # Limit download rate
- PARALLEL_DOWNLOADS: "50"    # Number of parallel downloads per client container

## Use Cases**

### Test throughput

- Choose the small file to stress the throughput. 
- Use the DELAY property to reduce the throughput.

### Test bandwidth

- Choose the large file to stress the bandwidth. 
- Use RATE_LIMIT to throttle the download rate.

### Control the number of pods

- Use the server and client replicas numbers to control the number of pods.

### Scale up and down

Use the following commands to scale up and down the amount of server and client pods:

```shell
kubectl scale deployment httpd-server --replicas=10 -n ks-load; kubectl scale deployment curl-client --replicas=100 -n ks-load
```

### Control the load

- You can add load by setting the PARALLEL_DOWNLOADS property to cause each client to trigger multiple parallel downloads.
