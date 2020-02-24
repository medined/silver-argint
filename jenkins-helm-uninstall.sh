#!/bin/bash

./jenkins-proxy-stop.sh

kubectl get pods -l "app.kubernetes.io/instance=jenkins" -o jsonpath="{.items[0].metadata.name}" > /dev/null 2>&1
if [ $? == 0 ]; then
    helm uninstall jenkins --namespace sandbox
else
  echo "###########################"
  echo "# Jenkins is not running. #"
  echo "###########################"
fi
