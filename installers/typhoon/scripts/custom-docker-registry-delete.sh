#!/bin/bash

# This script deletes a public docker registry from k8s.

if [ -z $K8S_REGISTRY_NAMESPACE ]; then
  echo "Please set K8S_REGISTRY_NAMESPACE env variable. For example, custom-docker-registry"
  exit
fi

kubectl delete ingress docker-registry --namespace $K8S_REGISTRY_NAMESPACE
kubectl delete service docker-registry --namespace $K8S_REGISTRY_NAMESPACE
kubectl delete pod docker-registry --namespace $K8S_REGISTRY_NAMESPACE
kubectl delete configmap docker-registry --namespace $K8S_REGISTRY_NAMESPACE
kubectl delete secret docker-registry --namespace $K8S_REGISTRY_NAMESPACE
kubectl delete certificate docker-registry --namespace $K8S_REGISTRY_NAMESPACE
