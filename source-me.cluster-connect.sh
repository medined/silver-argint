#!/bin/bash

# This script set the context and KOPS_STATE_STORE. It must be 
# sourced so that KOPS_STATE_STORE is set into the calling
# environment.

if [ $# -ne 2 ]; then
  echo "Usage: -f [configuration file]"
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

ENV_FILE=$2
source $ENV_FILE

if [ -z $AWS_ACCESS_KEY_ID ]; then
  echo "ERROR: Missing environment variable: AWS_ACCESS_KEY_ID"
  exit
fi
if [ -z $AWS_SECRET_ACCESS_KEY ]; then
  echo "ERROR: Missing environment variable: AWS_SECRET_ACCESS_KEY"
  exit
fi
if [ -z $AWS_REGION ]; then
  echo "ERROR: Missing environment variable: AWS_REGION"
  exit
fi
if [ -z $AWS_ZONE ]; then
  echo "ERROR: Missing environment variable: AWS_ZONE"
  exit
fi
if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  exit
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
