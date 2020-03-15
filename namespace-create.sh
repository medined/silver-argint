#!/bin/bash

NAMESPACE=${1:-sandbox}
INGRESS_NAME="$NAMESPACE"

cat <<EOF >yaml/namespace-$NAMESPACE.yaml
apiVersion: v1
kind: Namespace
metadata:
    name: $NAMESPACE
    labels:
        name: $NAMESPACE
EOF
kubectl apply -f yaml/namespace-$NAMESPACE.yaml

# Set the `kubectl` context so that `sandbox` is the current namespace. Undo
# this action by using `default` as the namespace.

kubectl config set-context --current --namespace=$NAMESPACE

helm list | grep $INGRESS_NAME > /dev/null
if [ $? != 0 ]; then
    helm install $INGRESS_NAME stable/nginx-ingress \
        --set controller.metrics.enabled=true
    sleep 10
fi

K8S_HOSTNAME=$(kubectl get service $INGRESS_NAME-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

#
# NOTE: How to wait for DNS to propagate. dig is not working reliably.

echo "$K8S_HOSTNAME will be ready in a few minutes. When it is ready, please"
echo "press <ENTER>."
echo
echo "dig $K8S_HOSTNAME"
echo
read -p "Press <ENTER> to continue."

echo "Load Balancer is ready for traffic: $K8S_HOSTNAME"
