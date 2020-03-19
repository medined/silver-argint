#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: -f [configuration file] <service>"
  echo
  echo "This script creates a vanity URL like register.va-oit.cloud using Route53."
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

unset DOMAIN_NAME

CONFIG_FILE=$2
source $CONFIG_FILE

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  exit
fi

SAFE_DOMAIN_NAME=$(echo $DOMAIN_NAME | tr '.' '-')
echo "SAFE_DOMAIN_NAME: $SAFE_DOMAIN_NAME"

# helm inspect values stable/nginx-ingress > yaml/nginx-ingress.values.yaml.original

helm list | grep $SAFE_DOMAIN_NAME > /dev/null
if [ $? == 0 ]; then
  echo "Ingress already installed."
else
    helm install $SAFE_DOMAIN_NAME stable/nginx-ingress
    echo 
    echo "------------------------------------------"
    echo "Use the following command to learn the load balancer endpoint."
    echo
    echo "  kubectl get service $SAFE_DOMAIN_NAME-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo"
    echo
    echo "Run 'dig <endpoint>' repeatly to know when the DNS entry has been propagated."
fi
