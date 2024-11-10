#!/bin/bash

# Initialize variables
TAG="master"
DEBUG=false
PACKET_CAPTURE="af_packet"  # Default value for packetCapture

# Function to display usage information
usage() {
    echo "Usage: $0 [debug] [version] [ebpf]"
    echo "  debug   : Enable verbose output"
    echo "  version : Specify the version/tag (e.g., v52.3.88)"
    echo "  ebpf    : Set packetCapture to 'ebpf' instead of 'af_packet'"
    exit 1
}

# Parse parameters
for arg in "$@"; do
    case $arg in
        debug)
            DEBUG=true
            ;;
        ebpf)
            PACKET_CAPTURE="ebpf"
            ;;
        *)
            if [ "$TAG" == "master" ]; then
                TAG="$arg"
            else
                echo "Error: Multiple version parameters provided."
                usage
            fi
            ;;
    esac
done

# Function to run commands with optional verbosity
run_command() {
    if [ "$DEBUG" == "true" ]; then
        echo "Executing: $*"
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

# Function to install kubeshark
install_kubeshark() {
    local helm_params=(
        --set tap.packetCapture="$PACKET_CAPTURE"
        --set tap.proxy.worker.srvPort=31001
        --set tap.docker.tag="$TAG"
        --set tap.storageLimit=100Gi
        --set supportChatEnabled=false
    )

    if [ "$TAG" == "master" ]; then
        # Install from local Helm chart directory
        run_command helm install kubeshark ~/work/GitHub/kubeshark/helm-chart "${helm_params[@]}"
    else
        # Install from official Helm repository with specified version
        run_command helm install kubeshark kubeshark/kubeshark --version "$TAG" "${helm_params[@]}"
    fi
}

# Function to simulate sleep with progress indication
mySleep() {
    local total_sleep=$1
    local interval=10
    local elapsed=0

    echo -n "Sleeping for $total_sleep seconds"
    while [ $elapsed -lt $total_sleep ]; do
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -n "."
    done
    echo
}

# Function to clean up resources
cleanUp() {
    run_command helm uninstall kubeshark

    local PID
    PID=$(lsof -ti tcp:8089)
    if [ -n "$PID" ]; then
        run_command kill -9 "$PID"
        run_command echo "Killed existing port-forward process on port 8089 (PID: $PID)"
    else
        run_command echo "No existing port-forward process found on port 8089"
    fi

    local PIDS
    PIDS=$(pgrep -f kubeshark)
    if [ -n "$PIDS" ]; then
        run_command echo "Found kubeshark processes with PIDs: $PIDS"
        run_command kill -9 "$PIDS"
        run_command echo "Killed kubeshark processes"
    else
        run_command echo "No kubeshark processes found"
    fi
}

apply_recording() {
    run_command curl 'http://0.0.0.0:8899/api/records' \
        -H 'Accept: */*' \
        -H 'Accept-Language: en-US,en;q=0.9' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'Content-Type: application/json' \
        -H 'Origin: http://0.0.0.0:8899' \
        -H 'Pragma: no-cache' \
        -H 'Referer: http://0.0.0.0:8899/?q=' \
        -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36' \
        -H 'X-Authorization:' \
        -H 'X-Kubeshark-Capture: ignore' \
        -H 'X-Refresh-Token:' \
        --data-raw '{"name":"example","query":"","cron":"* * * * * *","duration":3600000,"deleteAfter":172800000,"limit":1}' \
        --insecure
}

# Main script execution
cleanUp

install_kubeshark

mySleep 10

# Port forwarding the kubeshark front end
run_command kubeshark proxy --set headless=true &
KUBESHARK_PID=$!
mySleep 10

apply_recording

mySleep 30

timestamp=$(date +%s)

{
    sleep 1
    echo "record(\"example\")"
    sleep 60
} | wscat --connect ws://0.0.0.0:8899/api/ws > "/tmp/ws.$timestamp" &
WS_PID=$!
mySleep 30

# ANSI color codes
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# Get file size
file_size=$(wc -c < "/tmp/ws.$timestamp")

# Print file size with color based on size condition
if [ "$file_size" -gt 1000 ]; then
    echo -e "Size of ws.$timestamp: ${GREEN}${file_size}B${RESET}"
else
    echo -e "Size of ws.$timestamp: ${RED}${file_size}B${RESET}"
fi




if ps -p "$WS_PID" > /dev/null; then
     run_command kill "$WS_PID"
fi

if ps -p "$KUBESHARK_PID" > /dev/null; then
    run_command kill "$KUBESHARK_PID"
fi

cleanUp
