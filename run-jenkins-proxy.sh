#!/bin/bash

NAMESPACE=sandbox
NAME=jenkins

mkdir -p log

PASSWORD=$(kubectl get secret \
  --namespace $NAMESPACE \
  $NAME \
  -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)

POD=$(kubectl get pods \
  --namespace $NAMESPACE \
  -l "app.kubernetes.io/instance=$NAME" \
  -o jsonpath="{.items[0].metadata.name}")

ps f | grep $POD | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "#################################"
  echo "# The proxy is already running. #"
  echo "#################################"
else
  nohup kubectl \
    --namespace $NAMESPACE \
    port-forward \
    $POD \
    8080:8080 > log/jenkins-proxy.log 2>&1 &
fi

echo 
echo "#################################"
echo "# Password: $PASSWORD"
echo "# URL:      http://localhost:8080"
echo "#################################"
