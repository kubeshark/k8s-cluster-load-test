#!/bin/sh
kubectl config use-context kind-kind1
current_dir=$(pwd)
cd /tmp 
cd k8s-cluster-load-test
git checkout main
cd $current_dir
