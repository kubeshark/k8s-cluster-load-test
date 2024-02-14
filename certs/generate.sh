#!/bin/bash

# Check if cfssl is installed
if ! command -v cfssl &> /dev/null; then
    echo "cfssl could not be found. Please install it before running this script."
    exit 1
fi

# Define directories for output
WORKDIR="./cfssl"
CACFG="$WORKDIR/ca-config.json"
CACSR="$WORKDIR/ca-csr.json"
CERTCFG="$WORKDIR/cert-config.json"
CERTCSR="$WORKDIR/cert-csr.json"

# Create work directory
mkdir -p ${WORKDIR}

# Step 1: Generate CA configuration file
cat > ${CACFG} <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "server": {
        "usages": ["signing", "key encipherment", "server auth"],
        "expiry": "87600h"
      },
      "client": {
        "usages": ["signing", "key encipherment", "client auth"],
        "expiry": "87600h"
      }
    }
  }
}
EOF

# Step 2: Generate CA CSR (Certificate Signing Request) file
cat > ${CACSR} <<EOF
{
  "CN": "ks-load.svc.cluster.local",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "US",
    "L": "San Francisco",
    "O": "KubeShark",
    "OU": "CA",
    "ST": "California"
  }]
}
EOF

# Initialize CA
cfssl gencert -initca ${CACSR} | cfssljson -bare ${WORKDIR}/ca

# Step 3: Generate server certificate CSR configuration
cat > ${CERTCFG} <<EOF
{
  "CN": "*.dev.kubeshark.io",
  "hosts": [
    "localhost",
    "caddy-service.ks-load.svc.cluster.local",
    "127.0.0.1"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [{
    "C": "US",
    "L": "San Francisco",
    "O": "KubeShark",
    "OU": "Web",
    "ST": "California"
  }]
}
EOF

# Generate the certificate for *.ks-load.svc.cluster.local
cfssl gencert \
  -ca=${WORKDIR}/ca.pem \
  -ca-key=${WORKDIR}/ca-key.pem \
  -config=${CACFG} \
  -profile=server ${CERTCFG} | cfssljson -bare ${WORKDIR}/dev-kubeshark-io

# Copy the generated certificates to the caddy/certs directory
cp ${WORKDIR}/*.pem ../caddy/certs/

# Copy CA to the k6 directory
cp ${WORKDIR}/ca.pem ../k6/certs/