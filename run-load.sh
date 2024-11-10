#!/bin/bash

# Initialize variables
TAG="master"
DEBUG=false
PACKET_CAPTURE="af_packet"  # Default value for packetCapture
# ANSI color codes
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# Function to display usage information
function usage() {
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
function run_command() {
    if [ "$DEBUG" == "true" ]; then
        echo "Executing: $*"
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}
export -f run_command

# Function to install kubeshark
function install_kubeshark() {
    local helm_params=(
        --set tap.packetCapture="$PACKET_CAPTURE"
        --set tap.namespaces[0]=ks-load
        --set tap.namespaces[1]=sock-shop
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
function mySleep3() {
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

# Enhanced sleep function to optionally show file size if a file path is provided
function mySleep() {
    local total_sleep=$1
    local interval=10
    local elapsed=0
    local file_path=$2

    echo -n "Sleeping for $total_sleep seconds"
    while [ $elapsed -lt $total_sleep ]; do
        sleep $interval
        elapsed=$((elapsed + interval))

        # Check if file_path is provided and exists, then print its size
        if [ -n "$file_path" ] && [ -f "$file_path" ]; then
            file_size=$(wc -c < "$file_path")
            echo -ne "\rFile size of $file_path: ${file_size}B after $elapsed seconds..."
        else
            echo -n "."
        fi
    done
    echo # Newline after completion
}

function checkResources() {
    local URL="http://0.0.0.0:8899/api/health/workers"
    local data
    data=$(curl -s "$URL")

    echo "$data" | jq -c '.[]' | while read -r item; do
        local node_name
        local sniffer_cpu
        local tracer_cpu
        local sniffer_memory
        local tracer_memory
        local total_cpu
        local total_memory

        node_name=$(echo "$item" | jq -r '.nodeName')
        sniffer_cpu=$(echo "$item" | jq -r '.sniffer.cpuUsage // 0')
        tracer_cpu=$(echo "$item" | jq -r '.tracer.cpuUsage // 0')
        sniffer_memory=$(echo "$item" | jq -r '.sniffer.memoryUsage // 0')
        tracer_memory=$(echo "$item" | jq -r '.tracer.memoryUsage // 0')

        # Calculate total CPU and memory usage
        total_cpu=$(echo "$sniffer_cpu + $tracer_cpu" | bc -l)
        total_memory=$(echo "$sniffer_memory + $tracer_memory" | bc -l)

        # Format CPU usage to 2 decimal places
        total_cpu_formatted=$(printf "%.2f" "$total_cpu")

        # Format memory usage to human-readable format (GB or MB)
        if (( $(echo "$total_memory > 1073741824" | bc -l) )); then
            total_memory_formatted=$(printf "%.2f GB" "$(echo "$total_memory / 1073741824" | bc -l)")
        elif (( $(echo "$total_memory > 1048576" | bc -l) )); then
            total_memory_formatted=$(printf "%.2f MB" "$(echo "$total_memory / 1048576" | bc -l)")
        else
            total_memory_formatted="${total_memory} B"
        fi

        # Print resource information in green
        echo -e "${GREEN}Node: $node_name${RESET}"
        echo -e "${GREEN}  Total CPU Usage: ${total_cpu_formatted}${RESET}"
        echo -e "${GREEN}  Total Memory Usage: ${total_memory_formatted}${RESET}"

        # Check for CPU usage above threshold and print warning in red
        if (( $(echo "$total_cpu > 1" | bc -l) )); then
            echo -e "${RED}Warning: Total CPU Usage on $node_name is above threshold! (${total_cpu_formatted})${RESET}"
        fi

        # Check for Memory usage above threshold and print warning in red
        if (( $(echo "$total_memory > 1073741824" | bc -l) )); then
            echo -e "${RED}Warning: Total Memory Usage on $node_name is above threshold! (${total_memory_formatted})${RESET}"
        fi
    done
}


# Function to clean up resources
function cleanUp() {
    run_command kubectl delete -f k8s-cluster-load-test/load-test.yaml -f sock-shop-demo/deploy/kubernetes/complete-demo.yaml  --force --grace-period=0
    # rm -rf /tmp/k8s-cluster-load-test /tmp/sock-shop-demo
    run_command helm uninstall kubeshark
    
    local PID
    PID=$(lsof -ti tcp:8089)
    if [ -n "$PID" ]; then
        run_command kill -9 "$PID"
        echo "Killed existing port-forward process on port 8089 (PID: $PID)"
    fi

    local PIDS
    PIDS=$(pgrep -f kubeshark)
    if [ -n "$PIDS" ]; then
        echo "Found kubeshark processes with PIDs: $PIDS"
        run_command kill -9 "$PIDS"
        echo "Killed kubeshark processes"
    fi
}

# Main script execution
cleanUp

install_kubeshark

mySleep 10

current_dir=$(pwd)
cd /tmp
if [ ! -d "/path/to/folder" ]; then
    gh repo clone kubeshark/k8s-cluster-load-test -b load-test-1109024
    gh repo clone kubeshark/sock-shop-demo
fi
run_command kubectl apply -f k8s-cluster-load-test/load-test.yaml 
run_command kubectl apply -f sock-shop-demo/deploy/kubernetes/ws-demo.yaml
run_command kubectl apply -f sock-shop-demo/deploy/kubernetes/tls-demo.yaml


# echo "Port forwarding the kubeshark front end"
run_command kubeshark proxy --set headless=true &
KUBESHARK_PID=$!
# echo "kubeshark PID: $KUBESHARK_PID"

echo -e "\033[1mTesting resource utilization WITHOUT a websocket connection\033[0m"

mySleep 6  

checkResources

echo -e "\033[1mTesting resource utilization WITH a websocket connection\033[0m"

timestamp=$(date +%s)
file="/tmp/ws.load.$timestamp"

{
    sleep 1
    echo ""
    sleep 240
} | wscat --connect ws://0.0.0.0:8899/api/ws > "$file" 2>&1 &
WS_PID=$!
# echo "wscat PID: $WS_PID"
mySleep 18 $file

checkResources

# Get file size
file_size=$(wc -c < $file)

# Print file size with color based on size condition
if [ "$file_size" -gt 1000 ]; then
    echo -e "Size of $file: ${GREEN}${file_size}B${RESET}"
else
    echo -e "Size of $file: ${RED}${file_size}B${RESET}"
fi

if ps -p "$WS_PID" > /dev/null; then
    run_command kill "$WS_PID"
    # echo "Killed WebSocket process with PID $WS_PID"
fi

echo -e "\033[1mTesting HTTP2\033[0m"

file=/tmp/ws.http2.$timestamp

{
    sleep 1
    echo "http2"
    sleep 60
} | wscat --connect ws://0.0.0.0:8899/api/ws > "$file" 2>&1 &
WS_PID=$!
# echo "wscat PID: $WS_PID"
mySleep 30 $file

# Get file size
file_size=$(wc -c < $file)

# Print file size with color based on size condition
if [ "$file_size" -gt 1000 ]; then
    echo -e "Size of $file: ${GREEN}${file_size}B${RESET}"
else
    echo -e "Size of $file: ${RED}${file_size}B${RESET}"
fi


echo -e "\033[1mTesting WS\033[0m"

file=/tmp/ws.ws.$timestamp

{
    sleep 1
    echo "ws"
    sleep 60
} | wscat --connect ws://0.0.0.0:8899/api/ws > "$file" 2>&1 &
WS_PID=$!
# echo "wscat PID: $WS_PID"
mySleep 30 $file

# Get file size
file_size=$(wc -c < $file)

# Print file size with color based on size condition
if [ "$file_size" -gt 1000 ]; then
    echo -e "Size of $file: ${GREEN}${file_size}B${RESET}"
else
    echo -e "Size of $file: ${RED}${file_size}B${RESET}"
fi

echo -e "\033[1mTesting HTTPS\033[0m"

file=/tmp/ws.https.$timestamp

{
    sleep 1
    echo "tls and http"
    sleep 60
} | wscat --connect ws://0.0.0.0:8899/api/ws > "$file" 2>&1 &
WS_PID=$!
# echo "wscat PID: $WS_PID"
mySleep 30 $file

# Get file size
file_size=$(wc -c < $file)

# Print file size with color based on size condition
if [ "$file_size" -gt 1000 ]; then
    echo -e "Size of $file: ${GREEN}${file_size}B${RESET}"
else
    echo -e "Size of $file: ${RED}${file_size}B${RESET}"
fi



if ps -p "$WS_PID" > /dev/null; then
    run_command kill "$WS_PID"
    # echo "Killed WebSocket process with PID $WS_PID"
fi


if ps -p "$KUBESHARK_PID" > /dev/null; then
    run_command kill "$KUBESHARK_PID"
    # echo "Killed Kubeshark process with PID $KUBESHARK_PID"
fi

cleanUp
