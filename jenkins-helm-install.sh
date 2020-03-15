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

SERVICE_NAME=jenkins
NEW_DOMAIN_NAME="$SERVCE_NAME.$DOMAIN_NAME"

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

PASSWORD_FILENAME="password-jenkins-$NAMESPACE.txt"
LOCAL_PASSWORD_PATH="/tmp/$PASSWORD_FILENAME"

DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
S3_PASSWORD_KEY="$DOMAIN_NAME_S3/$PASSWORD_FILENAME"

echo
echo "Please add a password to $LOCAL_PASSWORD_PATH. It will be the"
echo "'admin' password for Jenkins. If needed, press ^C to create that"
echo "that file and then rerun this script."
echo
echo "You'll want to create and protect this password to make it"
echo "easier to use Jenkins easily and securely."
echo
read -p "Press <ENTER> to continue."

if [ ! -f $LOCAL_PASSWORD_PATH ]; then
  echo "ERROR: Missing password file: $LOCAL_PASSWORD_PATH"
  exit
fi

chmod 600 $LOCAL_PASSWORD_PATH
PASSWORD=$(cat $LOCAL_PASSWORD_PATH)

aws s3 cp $LOCAL_PASSWORD_PATH $S3_PASSWORD_KEY

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

helm install jenkins stable/jenkins \
  -f yaml/values.jenkins.yaml \
  --namespace $NAMESPACE

echo "Waiting for 30 seconds to get LoadBalancer host name."
sleep 30

K8S_HOSTNAME=$(kubectl get svc --namespace $NAMESPACE jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

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

#
# NOTE: How to wait for DNS to propagate. dig is not working reliably.