#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <service> <domain_name>"
  echo
  echo "This script creates a vanity URL like register.va-oit.cloud using Route53."
  exit
fi

SERVICE_NAME=$1
DOMAIN_NAME=$2

NEW_DOMAIN_NAME="$SERVICE_NAME.$DOMAIN_NAME"

#
# NOTE: How to wait for DNS to propagate. dig is not working reliably.

echo "Please run the following command to see if '$NEW_DOMAIN_NAME' already exists."
echo
echo "dig $NEW_DOMAIN_NAME"
echo
echo "If it does not exist, press <ENTER>. Otherwise, press ^C to end this script."
echo
read -p "Press <ENTER> to continue."

export HOSTED_ZONE_ID=$( \
  aws route53 list-hosted-zones-by-name \
    --query "HostedZones[?Name==\`$DOMAIN_NAME.\`].Id" \
    --output text \
)

SAFE_DOMAIN_NAME=$(echo $DOMAIN_NAME | tr '.' '-')

echo "NEW_DOMAIN_NAME: $NEW_DOMAIN_NAME"
echo "HOSTED_ZONE_ID: $HOSTED_ZONE_ID"
echo "SAFE_DOMAIN_NAME: $SAFE_DOMAIN_NAME"

helm list | grep $SAFE_DOMAIN_NAME > /dev/null
if [ $? != 0 ]; then
    helm install $SAFE_DOMAIN_NAME stable/nginx-ingress
    sleep 10
fi

K8S_HOSTNAME=$(kubectl get service $SAFE_DOMAIN_NAME-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "K8S_HOSTNAME: $K8S_HOSTNAME"

#
# NOTE: How to wait for DNS to propagate. dig is not working reliably.

echo "Please run the following command repeatly until the DNS entry has been propagated."
echo
echo "dig $K8S_HOSTNAME"
echo
read -p "Press <ENTER> to continue."

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
# NOTE: How to wait for DNS to propagate. dig is not working reliably.

echo "Your new vanity URL will be ready in a few minutes. When it is ready, please"
echo "press <ENTER>."
echo
echo "dig $NEW_DOMAIN_NAME"
echo
read -p "Press <ENTER> to continue."
