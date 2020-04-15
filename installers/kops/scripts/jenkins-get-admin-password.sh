#/bin/bash

NAMESPACE=${1:-sandbox}

printf $(kubectl get secret --namespace $NAMESPACE jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
