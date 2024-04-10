# Guide

## Run locally

`cd` into the source tree of `worker` repository.

Run:

```sh
make && make run
```

In this directory, run:

```sh
python3 ws.py
```

Run:

```sh
docker run --net=host --name k6s-load-server kubeshark/mert-k6s-load-server
```

Download and install `k6` binary from [here](https://github.com/grafana/k6/releases/tag/v0.50.0).

### HTTP (port 80)

Run:

```sh
k6 run -e URL=http://localhost loadtest.js
```

See below output in `stdout` of `python3 ws.py` process:

```
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
127.0.0.1 80
```

#### Conclusion

The many `127.0.0.1 80` lines is the proof that `worker` successfully captures and dissects unencrypted HTTP
traffic caused by the `loadtest.js` script.

### HTTPS (port 443)

Run:

```sh
k6 run -e URL=https://localhost:443 loadtest.js
```

Don't see `127.0.0.1 443` in `stdout` of `python3 ws.py` process.

#### Conclusion

`worker` can capture but **cannot** dissect the encrypted HTTP traffic (TLS) because it's encrypted.
`tracer` have to supply the unencrypted traffic into `worker` correctly.

## Run in Kubernetes cluster

Install Kubeshark

```sh
kubeshark clean && kubeshark tap
```

### HTTP (port 80)

Run:

```sh
kubectl apply -f ../load-test.yaml
```

Visit [http://127.0.0.1:8899/?q=request.path%20%3D%3D%20%22%2Fsmap.png%22](http://127.0.0.1:8899/?q=request.path%20%3D%3D%20%22%2Fsmap.png%22)

### HTTPS (port 443)

Run:

```sh
kubectl apply -f ../load-test-tls.yaml
```

Visit: [http://127.0.0.1:8899/?q=tls%20%3D%3D%20%22true%22](http://127.0.0.1:8899/?q=tls%20%3D%3D%20%22true%22)
