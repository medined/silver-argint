#/bin/bash

if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi

printf $(kubectl get secret --namespace $K8S_JENKINS_NAMESPACE jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
