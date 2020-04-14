#!/bin/bash

NAMESPACE=${1:-sandbox}
SERVICE_NAME=jenkins

echo "Pods"
echo "----"

kubectl get pods \
  --namespace $NAMESPACE \
  --selector "app.kubernetes.io/instance=$SERVICE_NAME"
echo 

echo "Services"
echo "--------"
kubectl get services \
  --namespace $NAMESPACE \
  --selector "app.kubernetes.io/instance=$SERVICE_NAME"
echo
