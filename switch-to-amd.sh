#!/bin/sh
current_dir=$(pwd)
cd /tmp 
cd k8s-cluster-load-test
git checkout load-test-1109024
cd $current_dir
