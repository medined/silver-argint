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

COUNT=$(dig $NEW_DOMAIN_NAME A +noall +answer | wc -l)
if [ $COUNT == 6 ]; then
  echo "Domain already exists: $NEW_DOMAIN_NAME"
  exit
fi

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

# Wait until the DNS has propagated for the load balancer hostname.

dig $K8S_HOSTNAME  | grep "ANSWER SECTION" -A 2 -m 1 | grep $K8S_HOSTNAME > /dev/null
while [ $? != 0 ]
do
    echo "Waiting 10 seconds for DNS to propagate."
    sleep 10
    dig $K8S_HOSTNAME  | grep "ANSWER SECTION" -A 2 -m 1 | grep $K8S_HOSTNAME > /dev/null
done

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

COUNT=$(dig $NEW_DOMAIN_NAME A +noall +answer | wc -l)
while [ $COUNT != 5 ]
do
    echo "Waiting 30 seconds for DNS to propagate which can take up to 10 minutes."
    sleep 30
    COUNT=$(dig $NEW_DOMAIN_NAME A +noall +answer | wc -l)
done
