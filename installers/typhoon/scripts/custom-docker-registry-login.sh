#!/bin/bash

if [ -z $K8S_DOMAIN_NAME ]; then
  echo "Please set K8S_DOMAIN_NAME env variable. For example, david.va-oit.cloud"
  exit
fi
if [ -z $K8S_REGISTRY_NAMESPACE ]; then
  echo "Please set K8S_REGISTRY_NAMESPACE env variable. For example, custom-docker-registry"
  exit
fi
if [ -z $K8S_REGISTRY_SERVICE_NAME ]; then
  echo "Please set K8S_REGISTRY_SERVICE_NAME env variable. For example, registry"
  exit
fi

VANITY_DOMAIN="$K8S_REGISTRY_SERVICE_NAME.$K8S_DOMAIN_NAME"
echo "VANITY_DOMAIN: $VANITY_DOMAIN"

PASSWORD=$(kubectl get secret --namespace $K8S_REGISTRY_NAMESPACE docker-registry-admin-password -o jsonpath="{.data.password}" | base64 --decode)
echo "PASSWORD: $PASSWORD"

docker login https://$VANITY_DOMAIN -u admin -p $PASSWORD
