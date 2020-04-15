#!/bin/bash

if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi

if [ $# -ne 1 ]; then
  echo "Usage: $0 <password>"
  exit
fi

PASSWORD=$1

kubectl -n $K8S_JENKINS_NAMESPACE get secret jenkins-admin-password 1>/dev/null 2>&1
if [ $? == 0 ]; then
    echo "Jenkins password secret exists. I don't want to overwrite it. Delete it manually."
  exit
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
    name: jenkins-admin-password
    namespace: $K8S_JENKINS_NAMESPACE
data:
    password: $(echo $PASSWORD | base64)
EOF
