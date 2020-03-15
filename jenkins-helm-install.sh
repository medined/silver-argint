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

SERVICE_NAME="jenkins"
NEW_DOMAIN_NAME="$SERVICE_NAME.$DOMAIN_NAME"

kubectl get pods \
  --namespace $NAMESPACE \
  --output jsonpath="{.items[0].metadata.name}" \
  --selector "app.kubernetes.io/instance=$SERVICE_NAME" > /dev/null 2>&1

if [ $? == 0 ]; then
  echo "###############################"
  echo "# Jenkins is already running. #"
  echo "###############################"
  exit
fi

# The jenkins password is stored in a secret. If you want to
# specify the password to use, pre-create the secret.

kubectl get secret jenkins-admin-password 1>/dev/null 2>&1
if [ $? == 0 ]; then
    echo "Jenkins password secret exists."
    PASSWORD=$(kubectl get secret --namespace $NAMESPACE jenkins-admin-password -o jsonpath="{.data.password}" | base64 --decode)
else
    PASSWORD=$(uuid)
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
    name: jenkins-admin-password
    namespace: $NAMESPACE
data:
    password: $(echo $PASSWORD | base64)
EOF
fi

# Be careful which plugins are installed using this method. As I tried
# different plugins, I ran into a log of initialization errors. I did 
# not take the time to look into the reasons.

cat <<EOF > yaml/values.jenkins.yaml
master:
  # run as non-root
  runAsUser: 1000
  fsGroup: 1000
  # set password
  adminPassword: $PASSWORD
  installPlugins:
    - command-launcher:1.4
    - credentials-binding
    - custom-tools-plugin
    - git
    - jdk-tool:1.4
    - kubernetes
    - kubernetes-cli
    - workflow-aggregator
    - workflow-job
  serviceType: LoadBalancer
  servicePort: 80
agent:
  enabled: true
  image: "medined/jnlp-slave-nodejs"
  tag: "13"
  alwaysPullImage: true
  volumes:
  - type: EmptyDir
    mountPath: /usr/local/sbin
EOF

helm install $SERVICE_NAME stable/jenkins \
  -f yaml/values.jenkins.yaml \
  --namespace $NAMESPACE

# Remove the file so the password is not stored locally.
rm -f yaml/values.jenkins.yaml

echo "Waiting for 45 seconds to get LoadBalancer host name."
sleep 45

K8S_HOSTNAME=$(kubectl get svc --namespace $NAMESPACE $SERVICE_NAME --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

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

export HOSTED_ZONE_ID=$( \
  aws route53 list-hosted-zones-by-name \
    --query "HostedZones[?Name==\`$DOMAIN_NAME.\`].Id" \
    --output text \
)

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://json/dns-action.json

echo "--------------"
echo
echo "Jenkins uses it own load-balancer (external endpoint)"
echo "Use ./jenkins-helm-check.sh to find what it is."
