#!/bin/bash

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

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  exit
fi

TEMPDIR=/tmp

DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
KOPS_STATE_STORE="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)-kops"

echo "kubernetes cluster: Deleting"

$HOME/bin/kops delete cluster --yes $DOMAIN_NAME

$HOME/bin/kubectl config delete-cluster $DOMAIN_NAME
$HOME/bin/kubectl config unset users.$DOMAIN_NAME
$HOME/bin/kubectl config unset users.$DOMAIN_NAME-basic-auth
$HOME/bin/kubectl config unset contexts.$DOMAIN_NAME
