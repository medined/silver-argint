# Create Vanity URL

When a LoadBalancer service is used to expose a service to the internet. Load balancer's have hard to remember URLs like `https://aed2c5f564bca4448b2fa3cd66e3c16b-1667984121.us-east-1.elb.amazonaws.com`. Users like friendly URLs like `registry.va-iot.cloud` and that's what this article shows how to do.

Remember that domains transcend AWS, they are availabe world-wide and provide a target for hackers. Anytime that you only your cluster to the outside, careful consideration to security needs must be made.

## Scripted Process

```
DOMAIN_NAME=va-oit.cloud
SERVICE_NAME=registry
./create-vanity-url.sh $SERVICE_NAME $DOMAIN_NAME
```

## Manual Process

* First, define the Route53 domain you'll be working with.

```
export DOMAIN_NAME=va-oit.cloud
```

* Define the service that will be exposed. This is the name of the subdomain you'll be creating.

```
export SERVICE_NAME=registry
export NEW_DOMAIN_NAME="$SERVICE_NAME.$DOMAIN_NAME"
```

* Now get the hosted zone id. For example, `/hostedzone/Z12M6H9O4AVOV1`

```
export HOSTED_ZONE_ID=$( \
  aws route53 list-hosted-zones-by-name \
    --query "HostedZones[?Name==\`$DOMAIN_NAME.\`].Id" \
    --output text \
)
echo "HOSTED_ZONE_ID: $HOSTED_ZONE_ID"
```

* Get the load balancer hostname assigned to your nginx-ingress-controller service.

```
K8S_HOSTNAME=$(kubectl get service dmm-nginx-ingress-controller --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $K8S_HOSTNAME
```

* Define the DNS action which is inserting or updating the echo hostname.

```

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
```

* Apply that DNS action to Route53.

```
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://json/dns-action.json
```

* Check the DNS record was created.

```
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query="ResourceRecordSets[?Name==\`$NEW_DOMAIN_NAME.\`]"
```

* Use the `dig` command to verify that the DNS change has been propagated. The command's output has several sections, to verify the propagation is complete, you are only interested in the `ANSWER SECTION` which is shown below.

```
dig $NEW_DOMAIN_NAME
;; ANSWER SECTION:
registry.va-oit.cloud.	101	IN	CNAME	aed2c5f564bca4448b2fa3cd66e3c16b-1667984121.us-east-1.elb.amazonaws.com.
aed2c5f564bca4448b2fa3cd66e3c16b-1667984121.us-east-1.elb.amazonaws.com. 60 IN A 18.209.243.159
aed2c5f564bca4448b2fa3cd66e3c16b-1667984121.us-east-1.elb.amazonaws.com. 60 IN A 18.235.223.163
```
