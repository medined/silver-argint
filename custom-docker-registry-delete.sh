#!/bin/bash

# This script deletes a public docker registry from k8s.

NAMESPACE=${1:-sandbox}

kubectl delete ingress docker-registry --namespace $NAMESPACE
kubectl delete service docker-registry --namespace $NAMESPACE
kubectl delete pod docker-registry --namespace $NAMESPACE
kubectl delete configmap docker-registry --namespace $NAMESPACE
kubectl delete secret docker-registry --namespace $NAMESPACE
kubectl delete certificate docker-registry --namespace $NAMESPACE
