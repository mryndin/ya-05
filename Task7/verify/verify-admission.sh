#!/bin/bash
echo "Testing PodSecurity Admission..."
kubectl apply -f ../insecure-manifests/ 2>&1 | grep -i "forbidden"