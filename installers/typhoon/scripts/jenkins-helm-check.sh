#!/bin/bash

if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi
if [ -z $K8S_JENKINS_SERVICE_NAME ]; then
  echo "Please set K8S_JENKINS_SERVICE_NAME env variable. For example, registry"
  exit
fi

echo "Pods"
echo "----"

kubectl get pods \
  --namespace $K8S_JENKINS_NAMESPACE \
  --selector "app.kubernetes.io/instance=$K8S_JENKINS_SERVICE_NAME"
echo 

echo "Services"
echo "--------"
kubectl get services \
  --namespace $K8S_JENKINS_NAMESPACE \
  --selector "app.kubernetes.io/instance=$K8S_JENKINS_SERVICE_NAME"
echo
