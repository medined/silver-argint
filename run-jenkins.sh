#!/bin/bash

cat <<EOF > yaml/values.jenkins.yaml
master:
  runAsUser: 1000
  fsGroup: 1000
  installPlugins:
    - git:4.1.1
    - kubernetes:1.23.4
    - nodejs:1.3.4
agent:
  enabled: true
  image: "medined/jnlp-slave"
  tag: "0.0.1"
  alwaysPullImage: true
EOF

    # - workflow-job:2.36
    # - workflow-aggregator:2.6
    # - credentials-binding:1.20
    # - github:4.0.0


helm install jenkins stable/jenkins -f yaml/values.jenkins.yaml --namespace sandbox
