#!/bin/bash
NAMESPACE=sandbox
kubectl delete namespace $NAMESPACE
kubectl delete clusterrole dmm-nginx-ingress
kubectl delete ClusterRoleBinding dmm-nginx-ingress

