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

# Wait until the DNS has propagated for the load balancer hostname.

COUNT=$(dig $K8S_HOSTNAME A +noall +answer | wc -l)
while [ $COUNT != 5 ]
do
    echo "Waiting 30 seconds for DNS to propagate which can take up to 10 minutes."
    sleep 30
    COUNT=$(dig $K8S_HOSTNAME A +noall +answer | wc -l)
done

echo "Load Balancer is ready for traffic: $K8S_HOSTNAME"
