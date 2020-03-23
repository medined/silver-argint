#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Usage: -f [configuration file] <namespace>"
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

unset DOMAIN_NAME

CONFIG_FILE=$2
NAMESPACE=$3
if [ ! -f $CONFIG_FILE ]; then
    echo "ERROR: Missing configuration file: $CONFIG_FILE"
    return
fi
source $CONFIG_FILE

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  return
fi

kubectl get namespace $NAMESPACE 1>/dev/null 2>&1
if [ $? != 0 ]; then
    echo "ERROR: Missing namespace: $NAMESPACE"
    echo "  Please run ./namespace-create.sh"
    exit
else
    echo "Namespace exists: $NAMESPACE"
fi

SERVICE_NAME="harbor"
HARBOR_HOST="$SERVICE_NAME.$DOMAIN_NAME"
ISSUER_REF=letsencrypt-production-issuer

helm list --namespace $NAMESPACE | grep $SERVICE_NAME > /dev/null
if [ $? != 0 ]; then
    helm repo add harbor https://helm.goharbor.io
    helm fetch harbor/harbor --untar
    # TODO: Configure values
    # TODO: install
    echo "Helm chart installed: $SERVICE_NAME"
else
    echo "Helm chart exists: $SERVICE_NAME"
fi


# Does the hosted zone exist?

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name==\`$DOMAIN_NAME.\`].Id" --output text)
if [ -z $HOSTED_ZONE_ID ]; then
  echo "ERROR: Domain missing from Route53 - $DOMAIN_NAME"
  echo "This script only works with domains hosted by Route53."
  exit
fi

# Does the sub-domain exist?

ENTRY=$(aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query 'ResourceRecordSets[?(Name==`$HARBOR_HOST.` && Type==`CNAME`)].Name' \
  --output text)
if [ -z $ENTRY ]; then
  echo "ERROR: Sub-domain missing from Route53 - $HARBOR_HOST"
  echo "This script only works with sub-domains hosted by Route53."
  exit
fi

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: harbor
  namespace: $NAMESPACE
spec:
  secretName: harbor-tls-certificate
  issuerRef:
    name: $ISSUER_REF
  dnsNames:
  - $HARBOR_HOST
EOF
