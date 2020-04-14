#!/bin/bash

NAMESPACE=${1:-sandbox}

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

# helm inspect values stable/nginx-ingress > yaml/nginx-ingress.values.yaml.original

# Installs services:
#   <namespace>-nginx-ingress-controller           LoadBalancer
#   <namespace>-nginx-ingress-controller-metrics   ClusterIP
#   <namespace>-nginx-ingress-default-backend      ClusterIP

helm list | grep $NAMESPACE > /dev/null
if [ $? != 0 ]; then
    helm install $NAMESPACE stable/nginx-ingress --set controller.metrics.enabled=true
    sleep 10
fi

echo "The load balancer for this namespace will be ready shortly."
echo
echo "Use the following command to get its endpoint."
echo
echo "  kubectl get service $NAMESPACE-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo"
echo
echo "Use dig to determine when it is propagated and safe to use. This will take several minutes."
echo
echo "  dig <endpoint>"
