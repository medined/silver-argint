#!/bin/bash

if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi

ps f | grep "kubectl --namespace $K8S_JENKINS_NAMESPACE port-forward $K8S_JENKINS_SERVICE_NAME" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "Run jenkins-proxy-stop.sh first."
  exit
fi

ps faux | grep "kubectl --namespace $K8S_JENKINS_NAMESPACE port-forward $K8S_JENKINS_SERVICE_NAME" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "Run jenkins-proxy-stop.sh first."
  exit
fi

kubectl get pods -l "app.kubernetes.io/instance=jenkins" -o jsonpath="{.items[0].metadata.name}" > /dev/null 2>&1
if [ $? == 0 ]; then
    helm uninstall jenkins --namespace $NAMESPACE
else
  echo "###########################"
  echo "# Jenkins is not running. #"
  echo "###########################"
fi
