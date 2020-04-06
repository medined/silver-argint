#!/bin/bash

if [ $# -ne 4 ]; then
  echo "Usage: -f [configuration file] <namespace> <service>"
  echo
  echo "This script creates a vanity URL like register.va-oit.cloud using Route53."
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

CONFIG_FILE=$2
NAMESPACE=$3
SERVICE_NAME=$4

unset DOMAIN_NAME
if [ ! -f $CONFIG_FILE ]; then
    echo "ERROR: Missing configuration file: $CONFIG_FILE"
    return
fi
source $CONFIG_FILE

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  return
fi

NEW_DOMAIN_NAME="$SERVICE_NAME.$DOMAIN_NAME"

# Does the hosted zone exist?

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name==\`$DOMAIN_NAME.\`].Id" --output text)
if [ -z $HOSTED_ZONE_ID ]; then
  echo "Domain [$DOMAIN_NAME] is missing from Route53."
  echo "This script only works with domains hosted by Route53."
  exit
else
  echo "Hosted Zone exists: $DOMAIN_NAME - $HOSTED_ZONE_ID"
fi

# Does the sub-domain exist?

ENTRY=$(aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query 'ResourceRecordSets[?(Name==`$NEW_DOMAIN_NAME.` && Type==`CNAME`)].Name' \
  --output text)
if [ ! -z $ENTRY ]; then
  echo "Sub-domain exists in Route53 - $NEW_DOMAIN_NAME"
  echo "use 'dig $NEW_DOMAIN_NAME' to see if it has propagated yet."
  exit
fi

SAFE_DOMAIN_NAME=$(echo $DOMAIN_NAME | tr '.' '-')

kubectl get service --namespace $NAMESPACE "$NAMESPACE-nginx-ingress-controller"
if [ $? != 0 ]; then
  echo "ERROR: Install ingress in the $NAMESPACE namespace before continuing."
  exit
fi

K8S_HOSTNAME=$(kubectl get service $NAMESPACE-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "K8S_HOSTNAME: $K8S_HOSTNAME"

cat <<EOF > json/dns-action.json
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$NEW_DOMAIN_NAME",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$K8S_HOSTNAME"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://json/dns-action.json

#
echo "Your new vanity sub-domain will be ready in a few minutes. Use the following command"
echo "to know when the the DNS entry has been propagated."
echo
echo "dig $NEW_DOMAIN_NAME"
echo
