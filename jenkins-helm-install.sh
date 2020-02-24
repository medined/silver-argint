#!/bin/bash

NAMESPACE=sandbox
NAME=jenkins

kubectl get pods \
  --namespace $NAMESPACE \
  --output jsonpath="{.items[0].metadata.name}" \
  --selector "app.kubernetes.io/instance=$NAME" > /dev/null 2>&1

if [ $? == 0 ]; then
  echo "###############################"
  echo "# Jenkins is already running. #"
  echo "###############################"
  exit
fi

# Be careful which plugins are installed using this method. As I tried
# different plugins, I ran into a log of initialization errors. I did 
# not take the time to look into the reasons.

JENKINS_ADMIN_PASSWORD=$(cat password-jenkins.txt)

cat <<EOF > yaml/values.jenkins.yaml
master:
  # run as non-root
  runAsUser: 1000
  fsGroup: 1000
  # set password
  adminPassword: $JENKINS_ADMIN_PASSWORD
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
