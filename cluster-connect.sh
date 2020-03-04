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

ENV_FILE=$2
source $ENV_FILE

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  return
fi

# The va-oit.cloud domain is not using the naming convention.
if [ $DOMAIN_NAME == "va-oit.cloud" ]; then
    KOPS_STATE_STORE=$(cat ~/va-oit-cloud-s3-bucket.txt)
else
    DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
    DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
    KOPS_STATE_STORE="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)-kops"
fi

kubectl config use-context $DOMAIN_NAME
