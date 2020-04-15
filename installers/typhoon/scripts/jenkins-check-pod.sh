#!/bin/bash

if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi

kubectl -n $K8S_JENKINS_NAMESPACE get pods | grep jenkins
