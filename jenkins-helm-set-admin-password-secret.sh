#!/bin/bash

NAMESPACE=$1
PASSWORD=$2

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
