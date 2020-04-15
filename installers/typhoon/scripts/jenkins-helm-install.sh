#!/bin/bash

if [ -z $K8S_DOMAIN_NAME ]; then
  echo "Please set K8S_DOMAIN_NAME env variable. For example, david.va-oit.cloud"
  exit
fi
if [ -z $K8S_JENKINS_NAMESPACE ]; then
  echo "Please set K8S_JENKINS_NAMESPACE env variable. For example, jenkins"
  exit
fi
if [ -z $K8S_JENKINS_SERVICE_NAME ]; then
  echo "Please set K8S_JENKINS_SERVICE_NAME env variable. For example, registry"
  exit
fi

echo "Creating namespace: $K8S_JENKINS_NAMESPACE"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: $K8S_JENKINS_NAMESPACE
    labels:
        name: $K8S_JENKINS_NAMESPACE
EOF

SERVICE_NAME=$K8S_JENKINS_SERVICE_NAME
JENKINS_HOST="$SERVICE_NAME.$K8S_DOMAIN_NAME"
ISSUER="letsencrypt-production"

# The jenkins password is stored in a secret. If you want to
# specify the password to use, pre-create the secret.

kubectl -n $K8S_JENKINS_NAMESPACE get secret jenkins-admin-password 1>/dev/null 2>&1
if [ $? == 0 ]; then
    echo "Jenkins password secret exists."
    PASSWORD=$(kubectl get secret --namespace $K8S_JENKINS_NAMESPACE jenkins-admin-password -o jsonpath="{.data.password}" | base64 --decode)
else
    PASSWORD=$(uuid)
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
    name: jenkins-admin-password
    namespace: $K8S_JENKINS_NAMESPACE
data:
    password: $(echo $PASSWORD | base64)
EOF
fi

# Be careful which plugins are installed using this method. As I tried
# different plugins, I ran into a log of initialization errors. I did 
# not take the time to look into the reasons.

cat <<EOF > /tmp/values.jenkins.yaml
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

helm list --namespace $K8S_JENKINS_NAMESPACE | grep $SERVICE_NAME > /dev/null
if [ $? != 0 ]; then
    helm install $SERVICE_NAME stable/jenkins \
        -f /tmp/values.jenkins.yaml \
        --namespace $K8S_JENKINS_NAMESPACE
    echo "Helm chart installed: $SERVICE_NAME"
else
    echo "Helm chart exists: $SERVICE_NAME"
fi

# Remove the file so the password is not stored locally.
rm -f yaml/values.jenkins.yaml

SA_NAME="jenkins-deployer"
CRB_NAME="jenkins-deployer-role"

kubectl get serviceaccount $SA_NAME --namespace $K8S_JENKINS_NAMESPACE 1>/dev/null 2>&1
if [ $? != 0 ]; then
  kubectl create serviceaccount $SA_NAME --namespace $K8S_JENKINS_NAMESPACE
  echo "Service account created: $SA_NAME"
else
  echo "Service account exists: $SA_NAME"
fi

kubectl get clusterrolebinding $CRB_NAME 1>/dev/null 2>&1
if [ $? != 0 ]; then
  kubectl create clusterrolebinding $CRB_NAME \
    --clusterrole=cluster-admin \
    --serviceaccount=$K8S_JENKINS_NAMESPACE:$SA_NAME
  echo "Cluster Role Binding created: $CRB_NAME"
else
  echo "Cluster Role Binding exists: $CRB_NAME"
fi

echo
echo "Run the following command. Wait until the pods are ready."
echo
echo "  ./jenkins-helm-check.sh $K8S_JENKINS_NAMESPACE"
echo
