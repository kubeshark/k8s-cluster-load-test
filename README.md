# Configurable Kubernetes Cluster Load Test

This repository is useful for conducting load tests on your Kubernetes cluster.

## HTTP (1) Load Test

This script is a **k6 load testing scenario** that sends repeated HTTP GET requests with dynamic parameters while simulating multiple virtual users.

### Parameters (via environment variables)

* `URL` – Target URL (default: `http://localhost`).
* `VUS` – Number of virtual users (default: `10`).
* `DURATION` – How long to sustain the load stage (default: `30s`).
* `CONNECTION` – Value for the `Connection` header (default: `close`).
* `SLEEP` – Seconds to pause between iterations per user (default: `1`).

### Behavior

* Defines **stages**:

  1. Ramp up to the target number of VUs over 20 seconds.
  2. Sustain that load for the given duration.
* Each VU repeatedly:

  * Builds a GET request to `URL`, appending query params:

    * `i` – unique identifier composed of VU number and iteration (`__VU-__ITER`).
    * `connection` – reflects the `CONNECTION` env setting.
  * Sends the request with the specified `Connection` header.
  * Checks whether the response status is `200`.
  * Sleeps for `SLEEP` seconds before repeating.

In short: it **simulates concurrent users sending GET requests with unique identifiers, verifying 200 responses, and pacing requests with configurable sleep intervals.**

Do you also want me to condense this into a **single-line summary** (like a code comment at the top), similar to what might go above the Go code?



The load test is composed of two sets of either client or server pods:

- N * k6-load-test
- M * server

A total of M+N pods are launched, where N is the number of k6-load-test replicas, and M is the number of server replicas. Both replica numbers can be configured in the `load-test.yaml` manifest.

### Configuration

```yaml
    metadata:
      name: k6-load-test
      namespace: ks-load-c
    spec:
      replicas: 1 # number of load clients
      containers:
      - name: k6
        image: kubeshark/k6s-load-test:v52.3.88
        imagePullPolicy: IfNotPresent
        env:
          - name: VUS
            value: "10"
          - name: DURATION
            value: "5m"
          - name: URL
            value: "http://server.ks-load-s.svc.cluster.local/"
          - name: SLEEP
            value: "2"
```
### Available Files to Download

505742B - http://server.ks-load.svc.cluster.local/smap.png

1024B   - http://server.ks-load.svc.cluster.local/1k.png

12164B   - http://server.ks-load.svc.cluster.local/ks_logo.png


## HTTP2 Load Test

An HTTP client load tester that repeatedly opens new connections and sends requests, while logging both the full requests and responses.

### Parameters

The program requires **4 arguments**:

1. `<URL>` – The target URL to send requests to.
2. `<N>` – The number of requests to send per connection loop.
3. `<D>` – The delay (in seconds) between consecutive requests.
4. `<http_version>` – The HTTP version to use: `"1"` for HTTP/1.1 or `"2"` for HTTP/2 (cleartext).

### Behavior

* Chooses the appropriate transport depending on the HTTP version (`http.Transport` for 1.1, `http2.Transport` for 2).
* For each connection loop:

  * Sends `N` GET requests to the URL.
  * Each request appends query parameters:

    * `index` – request number in the current loop.
    * `loop_index` – connection loop number.
    * `timestamp` – Unix timestamp at the time of request.
  * Logs the full HTTP request and response (headers and body).
  * Waits `D` seconds before the next request.
* After `N` requests, closes idle connections and waits **10 seconds** before starting a new connection loop.

Essentially, it **tests HTTP/1.1 or HTTP/2 request/response handling** with indexed and timestamped queries, while simulating repeated connection cycles.

Do you want me to also rewrite this into a **shorter one-line description** (e.g., for documentation headers), or keep it at this detail level?

```yaml
    metadata:
      name: go-http2-client
      namespace: ks-load
    spec:
      replicas: 1 # number of load clients
          containers:
          - name: go-http2-client
            image: kubeshark/go-http2-client:v52.3.88
            imagePullPolicy: IfNotPresent
            env:
              - name: URL
                value: "http://http2-server.ks-load.svc.cluster.local/"
              - name: "N"
                value: "1"
              - name: "D"
                value: "1"
              - name: "V"
                value: "1"
```

## Testing with TLS

All files are available also via TLS.
Just replace `http://` with `https://` in URL value.

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

## Testing the results

Use the following Agent code to check whether messages are missing, assuming messages include the following query in the URL: `<test-url>?i=<user#>-<iteration-#`. 
For example: `/?i=3-1`

### HTTP Agent Code

```javascript
/**
 * Agent: MissingSequenceTracker (Color thresholds + Total Summary)
 *
 * Tracks `i=m-n` query parameters and reports:
 * - Missing stats by prefix (with colored threshold)
 * - Average missing percentage
 * - Total missing out of total observed
 */

var sequences = {};

// ANSI Colors
var blue = "\x1b[34m";
var yellow = "\x1b[33m";
var green = "\x1b[32m";
var red = "\x1b[31m";
var bold = "\x1b[1m";
var reset = "\x1b[0m";

function onItemCaptured(data) {
    try {
        if (!data || !data.request || !data.request.queryString) return;

        var iParam = data.request.queryString["i"];
        if (!iParam || typeof iParam !== "string") return;

        var parts = iParam.split("-");
        if (parts.length !== 2) return;

        var prefix = parts[0];
        var suffix = parseInt(parts[1], 10);
        if (isNaN(suffix)) return;

        if (!sequences[prefix]) {
            sequences[prefix] = {};
        }

        sequences[prefix][suffix] = true;
    } catch (e) {
        console.error(red + "Error processing query param i: " + reset, e);
    }
}

function getColorForPercent(pct) {
    if (pct > 5) return red;
    if (pct > 0) return yellow;
    return green;
}

function logMissingSequences() {
    try {
        var logLines = ["\n" + bold + "Sequence Report:" + reset];
        var totalMissing = 0;
        var totalCount = 0;
        var prefixCount = 0;
        var prefixSumPercent = 0;

        for (var prefix in sequences) {
            if (!sequences.hasOwnProperty(prefix)) continue;

            var nums = [];
            for (var key in sequences[prefix]) {
                if (sequences[prefix].hasOwnProperty(key)) {
                    nums.push(parseInt(key, 10));
                }
            }

            if (nums.length === 0) continue;

            nums.sort(function (a, b) { return a - b; });
            var min = nums[0];
            var max = nums[nums.length - 1];
            var count = max - min + 1;

            var missing = 0;
            for (var n = min; n <= max; n++) {
                if (!sequences[prefix][n]) {
                    missing++;
                }
            }

            var percent = (missing / count) * 100;
            var percentText = percent.toFixed(2);
            var color = getColorForPercent(percent);

            logLines.push(
                blue + "- " + prefix + "-[" + min + "-" + max + "]" + reset + ": " +
                color + missing + " missing of " + count + " (" + percentText + "%)" + reset
            );

            totalMissing += missing;
            totalCount += count;
            prefixSumPercent += percent;
            prefixCount++;
        }

        if (prefixCount > 0 && totalCount > 0) {
            var avgPrefixPercent = (prefixSumPercent / prefixCount).toFixed(2);
            var avgTotalPercent = ((totalMissing / totalCount) * 100).toFixed(2);
            var avgColor = getColorForPercent(avgTotalPercent);

            logLines.push("");
            logLines.push(
                bold + green + "Average per-prefix missing: " + avgPrefixPercent + "%" + reset
            );
            logLines.push(
                bold + avgColor + "Overall missing: " + totalMissing + " of " +
                totalCount + " = " + avgTotalPercent + "%" + reset
            );
        }

        if (logLines.length > 1) {
            console.log(logLines.join("\n"));
        }
    } catch (e) {
        console.error(red + "Error logging sequences: " + reset, e);
    }
}

if (utils.nodeName() !== "hub") {
    jobs.schedule("log-missing-sequences", "*/10 * * * * *", logMissingSequences);
}
```


### TCP Agent Code

To check, how message loss in TCP, enable TCP dissector.

```javascript
/**
 * Agent: TcpPayloadSequenceTracker (ES5-compatible)
 *
 * Purpose:
 * Tracks suffixes in TCP payloads starting with:
 *   "GET /?i=X-Y"
 * Extracts X and Y, builds sequence map per prefix.
 * Logs:
 * - Min/max range
 * - Missing count and percentage
 * - Global totals across all prefixes
 */

var sequences = {}; // { prefix: { suffix: true } }
var red = "\x1b[31m";
var green = "\x1b[32m";
var blue = "\x1b[34m";
var reset = "\x1b[0m";
var bold = "\x1b[1m";

/**
 * Hook: onItemCaptured
 */
function onItemCaptured(data) {
    try {
        if (!data || !data.data || !data.data.payload) return;

        var payload = String(data.data.payload);
        if (payload.indexOf("GET /?i=") !== 0) return;

        var match = payload.match(/i=([0-9]+)-([0-9]+)/);
        if (!match || match.length !== 3) return;

        var prefix = match[1];
        var suffix = parseInt(match[2], 10);
        if (isNaN(suffix)) return;

        if (!sequences[prefix]) sequences[prefix] = {};
        sequences[prefix][suffix] = true;
    } catch (e) {
        console.error("Error processing TCP payload:", e);
    }
}

/**
 * Job: logMissingSequences
 */
function logMissingSequences() {
    try {
        var logLines = [bold + "TCP Payload Sequence Report:" + reset];
        var globalMissing = 0;
        var globalTotal = 0;

        for (var prefix in sequences) {
            if (!sequences.hasOwnProperty(prefix)) continue;

            var nums = [];
            for (var key in sequences[prefix]) {
                if (sequences[prefix].hasOwnProperty(key)) {
                    nums.push(parseInt(key, 10));
                }
            }

            if (nums.length === 0) continue;

            nums.sort(function (a, b) { return a - b; });
            var min = nums[0];
            var max = nums[nums.length - 1];

            var missingCount = 0;
            var total = max - min + 1;

            for (var n = min; n <= max; n++) {
                if (!sequences[prefix][n]) {
                    missingCount++;
                }
            }

            var missingPercent = ((missingCount / total) * 100).toFixed(2);
            globalMissing += missingCount;
            globalTotal += total;

            logLines.push(
                "- " + blue + prefix + "-[" + min + "-" + max + "]" + reset +
                ": Missing " + red + missingCount + reset +
                " out of " + green + total + reset +
                " = " + bold + missingPercent + "%" + reset
            );
        }

        if (globalTotal > 0) {
            var globalPercent = ((globalMissing / globalTotal) * 100).toFixed(2);
            logLines.push(
                "\n" + bold + "Global Summary: " +
                red + globalMissing + reset + " missing out of " +
                green + globalTotal + reset +
                " (" + blue + globalPercent + "%" + reset + ")"
            );
        }

        if (logLines.length > 1) {
            console.clear();
            console.log(logLines.join("\n"));
        }
    } catch (e) {
        console.error("Error logging TCP sequences:", e);
    }
}

// Schedule worker-only report
if (utils.nodeName() !== "hub") {
    jobs.schedule("log-tcp-missing-sequences", "*/10 * * * * *", logMissingSequences);
}
```
