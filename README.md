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

## How to Run

Optinally alter its properties and apply The [load-test.yaml](load-test.yaml) manifest:
```shell
kubectl apply -f load-test.yaml
```
## View outcome with Kubeshark

Run the following command:
```shell
kubeshark tap -n ks-load
```
And see the results:

<img width="1387" alt="image" src="https://github.com/kubeshark/k8s-cluster-load-test/assets/1990761/f2b70fe3-ab9a-4322-85f0-27b7a052f25a">
<img width="1434" alt="image" src="https://github.com/kubeshark/k8s-cluster-load-test/assets/1990761/bc8deda2-1a87-40cd-89fe-ad9027541b45">


