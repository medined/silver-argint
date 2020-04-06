#!/bin/bash

(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0
if [ "$SOURCED" == "0" ]; then
  echo "ERROR: Please source this script."
  exit
fi

# This script set the context and KOPS_STATE_STORE. It must be 
# sourced so that KOPS_STATE_STORE is set into the calling
# environment.

if [ $# -ne 2 ]; then
  echo "Usage: -f [configuration file]"
  return
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    return
fi

CONFIG_FILE=$2

if [ ! -f $CONFIG_FILE ]; then
    echo "ERROR: Missing configuration file: $CONFIG_FILE"
    return
fi

source $CONFIG_FILE

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  return
fi

./dashboard-proxy-stop.sh
./jenkins-proxy-stop.sh

DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
export KOPS_STATE_STORE="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)-kops"

kubectl config use-context $DOMAIN_NAME

if [ ! -z $NAMESPACE ]; then
  kubectl config set-context --current --namespace=$NAMESPACE
fi

echo
echo "Don't forget to start the dashbaord and jenkins proxys if needed."
echo
echo "./dashboard-proxy-stop.sh"
echo "./jenkins-proxy-stop.sh"
