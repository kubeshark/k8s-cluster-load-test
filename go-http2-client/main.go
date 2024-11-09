package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"

	"golang.org/x/net/http2"
)

func main() {
	if len(os.Args) != 5 {
		fmt.Println("Usage: ./app <URL> <N> <D> <http_version>: ", os.Args)
		fmt.Println("       <http_version>: '1' for HTTP/1.1, '2' for HTTP/2")
		os.Exit(1)
	}

	urlStr := os.Args[1]
	N, err := strconv.Atoi(os.Args[2])
	D, err := strconv.Atoi(os.Args[3])
	if err != nil {
		fmt.Println("Invalid number of requests:", os.Args[2])
		os.Exit(1)
	}

	httpVersion := os.Args[4]
	var client *http.Client
	var transport http.RoundTripper

	if httpVersion == "2" {
		tr := &http2.Transport{
			AllowHTTP: true,
			DialTLSContext: func(ctx context.Context, network, addr string, cfg *tls.Config) (net.Conn, error) {
				var d net.Dialer
				return d.DialContext(ctx, network, addr)
			},
			TLSClientConfig: &tls.Config{
				InsecureSkipVerify: true, // Skip verification for testing; adjust as necessary
			},
		}
		client = &http.Client{Transport: tr}
		transport = tr
		fmt.Println("Using HTTP/2 over HTTP")
	} else if httpVersion == "1" {
		tr := &http.Transport{}
		client = &http.Client{Transport: tr}
		transport = tr
		fmt.Println("Using HTTP/1.1")
	} else {
		fmt.Println("Invalid HTTP version specified. Use '1' for HTTP/1.1 or '2' for HTTP/2.")
		os.Exit(1)
	}

	for loopIndex := 0; ; loopIndex++ {
		fmt.Println("Starting new connection...")
		for i := 0; i < N; i++ {
			fmt.Println("Getting URL:", urlStr)

			// Add the query parameters
			u, err := url.Parse(urlStr)
			if err != nil {
				fmt.Println("Failed to parse URL:", err)
				continue
			}

			q := u.Query()
			q.Set("index", strconv.Itoa(i+1))                            // First index (1 - N)
			q.Set("loop_index", strconv.Itoa(loopIndex+1))               // Second index for every loop iteration
			q.Set("timestamp", strconv.FormatInt(time.Now().Unix(), 10)) // Third param: current timestamp
			u.RawQuery = q.Encode()

			req, err := http.NewRequest("GET", u.String(), nil)
			if err != nil {
				fmt.Println("Failed to create request:", err)
				continue
			}

			// Log the full HTTP request
			var reqBuf bytes.Buffer
			req.Write(&reqBuf)
			fmt.Println("Full HTTP Request:")
			fmt.Println(reqBuf.String())

			resp, err := client.Do(req)
			if err != nil {
				fmt.Println("Failed to send request:", err)
				continue
			}

			// Log the full HTTP response
			var respBuf bytes.Buffer
			fmt.Println("Full HTTP Response:")
			fmt.Printf("HTTP/%.1f %s\n", resp.ProtoMajor, resp.Status)
			for k, v := range resp.Header {
				for _, h := range v {
					fmt.Printf("%s: %s\n", k, h)
				}
			}
			fmt.Println()

			// Copy response body for logging
			body, err := io.ReadAll(resp.Body)
			if err != nil {
				fmt.Println("Failed to read response body:", err)
				continue
			}
			resp.Body.Close()

			respBuf.Write(body)
			fmt.Println(respBuf.String())

			fmt.Printf("Request %d: Status Code %d\n", i+1, resp.StatusCode)
			time.Sleep(time.Duration(D) * time.Second) // Sleep for D seconds
		}

		// Close idle connections after N requests
		if transport != nil {
			if tr, ok := transport.(interface{ CloseIdleConnections() }); ok {
				fmt.Println("Closing idle connections...")
				tr.CloseIdleConnections()
			}
		}

		fmt.Println("Sleeping for 10 seconds before starting a new connection...")
		time.Sleep(10 * time.Second) // Sleep for 10 seconds before starting a new connection
	}
}
