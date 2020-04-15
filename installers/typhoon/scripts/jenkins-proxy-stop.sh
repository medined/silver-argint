#!/bin/bash

if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi
if [ -z $K8S_JENKINS_SERVICE_NAME ]; then
  echo "Please set K8S_JENKINS_SERVICE_NAME env variable. For example, registry"
  exit
fi

ps f | grep "kubectl --namespace $K8S_JENKINS_NAMESPACE port-forward $K8S_JENKINS_SERVICE_NAME" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  PID=$(ps f | grep "kubectl --namespace $K8S_JENKINS_NAMESPACE port-forward $K8S_JENKINS_SERVICE_NAME" | grep -v grep | awk '{print $1}')
  kill $PID
  echo "Killed process: $PID"
fi

ps faux | grep "kubectl --namespace $K8S_JENKINS_NAMESPACE port-forward $K8S_JENKINS_SERVICE_NAME" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "ERROR: Unable to kill jenkins proxy."
else
  echo "Jenkins proxy is gone."
fi
