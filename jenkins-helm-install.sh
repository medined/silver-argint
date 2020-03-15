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
  serviceType: ClusterIP
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

helm list --namespace $NAMESPACE | grep $SERVICE_NAME > /dev/null
if [ $? != 0 ]; then
    helm install $SERVICE_NAME stable/jenkins -f yaml/values.jenkins.yaml --namespace $NAMESPACE
    echo "Helm chart installed: $SERVICE_NAME"
else
    echo "Helm chart exists: $SERVICE_NAME"
fi

# Remove the file so the password is not stored locally.
rm -f yaml/values.jenkins.yaml

SA_NAME="jenkins-deployer"
CRB_NAME="jenkins-deployer-role"

kubectl get serviceaccount $SA_NAME --namespace $NAMESPACE 1>/dev/null 2>&1
if [ $? != 0 ]; then
  kubectl create serviceaccount $SA_NAME --namespace $NAMESPACE
  echo "Service account created: $SA_NAME"
else
  echo "Service account exists: $SA_NAME"
fi

kubectl get clusterrolebinding $CRB_NAME 1>/dev/null 2>&1
if [ $? != 0 ]; then
  kubectl create clusterrolebinding $CRB_NAME --clusterrole=cluster-admin --serviceaccount=sandbox:jenkins-deployer
  echo "Cluster Role Binding created: $CRB_NAME"
else
  echo "Cluster Role Binding exists: $CRB_NAME"
fi

./jenkins-proxy-start.sh