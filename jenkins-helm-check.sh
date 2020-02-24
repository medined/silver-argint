#!/bin/bash

NAMESPACE=sandbox
NAME=jenkins

echo "Pods"
echo "----"

kubectl get pods \
  --namespace $NAMESPACE \
  --selector "app.kubernetes.io/instance=$NAME"
echo 

echo "Services"
echo "--------"
kubectl get services \
  --namespace $NAMESPACE \
  --selector "app.kubernetes.io/instance=$NAME"
echo