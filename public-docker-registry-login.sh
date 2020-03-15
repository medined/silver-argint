#!/bin/bash

NAMESPACE=${1:-sandbox}
SERVICE_NAME=registry

CURRENT_CONTEXT=$(kubectl config view -o jsonpath="{.current-context}")
VANITY_URL="$SERVICE_NAME.$CURRENT_CONTEXT"
echo "VANITY_URL: $VANITY_URL"

PASSWORD=$(kubectl get secret --namespace $NAMESPACE docker-registry-admin-password -o jsonpath="{.data.password}" | base64 --decode)
echo "PASSWORD: $PASSWORD"

docker login https://$VANITY_URL -u admin -p $PASSWORD
