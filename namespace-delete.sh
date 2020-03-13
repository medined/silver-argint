#!/bin/bash

NAMESPACE=${1:-sandbox}
INGRESS_NAME="$NAMESPACE"

kubectl delete namespace $NAMESPACE
kubectl delete clusterrole $NAMESPACE-nginx-ingress
kubectl delete ClusterRoleBinding $NAMESPACE-nginx-ingress
