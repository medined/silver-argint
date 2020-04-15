#!/bin/bash

if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi
if [ -z $K8S_JENKINS_SERVICE_NAME ]; then
  echo "Please set K8S_JENKINS_SERVICE_NAME env variable. For example, registry"
  exit
fi

kubectl get pods \
  --selector "app.kubernetes.io/instance=jenkins" \
  --output jsonpath="{.items[0].metadata.name}" \
  --namespace $K8S_JENKINS_NAMESPACE > /dev/null 2>&1
  
if [ $? != 0 ]; then
  echo "ERROR: Don't start the Jenkins proxy without Jenkins running."
  exit 1
fi

mkdir -p log

PASSWORD=$(kubectl get secret \
  --namespace $K8S_JENKINS_NAMESPACE \
  $K8S_JENKINS_SERVICE_NAME \
  -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)

POD=$(kubectl get pods \
  --namespace $K8S_JENKINS_NAMESPACE \
  -l "app.kubernetes.io/instance=$K8S_JENKINS_SERVICE_NAME" \
  -o jsonpath="{.items[0].metadata.name}")

ps f | grep $POD | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "#################################"
  echo "# The proxy is already running. #"
  echo "#################################"
else
  nohup kubectl \
    --namespace $K8S_JENKINS_NAMESPACE \
    port-forward \
    $POD \
    8080:8080 > log/jenkins-proxy.log 2>&1 &
fi

echo 
echo "#################################"
echo "# Password: $PASSWORD"
echo "# URL:      http://localhost:8080"
echo "#################################"
