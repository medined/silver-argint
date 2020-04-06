#!/bin/bash

# This script deploys JupyterHub into the Ks cluster. This allows users
# to run interactive notebooks.

CONTACT_EMAIL=$1
VANITY_URL=$2

TOKEN=$(openssl rand -hex 32)

######
# Don't use a load balancer. Instead use the ingress load balancer.

cat <<EOF > yaml/jupyter-config.yaml
proxy:
    secretToken: $TOKEN
    service:
        type: ClusterIP
singleuser:
    extraEnv:
        EDITOR: vim
    image:
        # Get the latest image tag at:
        # https://hub.docker.com/r/jupyter/datascience-notebook/tags/
        # Inspect the Dockerfile at:
        # https://github.com/jupyter/docker-stacks/tree/master/datascience-notebook/Dockerfile
        name: jupyter/datascience-notebook
        tag: 177037d09156
EOF

helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

NAMESPACE=jupyterhub
RELEASE=jupyterhub

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: $NAMESPACE
    labels:
        name: $NAMESPACE
EOF

# Use the following command to see the possible values in the helm
# chart.
# helm inspect values jupyterhub/jupyterhub > yaml/jupyterhub.values.yaml.original

# Install the chart if needed.
helm list --namespace $NAMESPACE | grep $RELEASE > /dev/null
if [ $? != 0 ]; then
    helm upgrade --install $RELEASE jupyterhub/jupyterhub \
    --namespace $NAMESPACE  \
    --version=0.8.2 \
    --values yaml/jupyter-config.yaml
    echo "Helm chart installed: $SERVICE"
else
    echo "Helm chart exists: $SERVICE"
fi

echo "Please create a vanity URL jupyterhub.<domain> which uses a CNAME"
echo "to point to the LoadBalancer for the jupyterhub proxy-public service."
echo
echo "Use the following command to find the LoadBalancer external endpoint"
echo "  kubectl get service proxy-public --namespace jupyterhub"
echo
echo "Wait until the vanity URL is reachable by dig before continuing."
echo
read -p "Press <ENTER> to continue."

cat <<EOF > yaml/jupyter-config.yaml
proxy:
    https:
        hosts:
            - $VANITY_URL
        letsencrypt:
            contactEmail: $CONTACT_EMAIL
    secretToken: $TOKEN
singleuser:
    extraEnv:
        EDITOR: vim
    image:
        # Get the latest image tag at:
        # https://hub.docker.com/r/jupyter/datascience-notebook/tags/
        # Inspect the Dockerfile at:
        # https://github.com/jupyter/docker-stacks/tree/master/datascience-notebook/Dockerfile
        name: jupyter/datascience-notebook
        tag: 177037d09156
EOF

helm upgrade $RELEASE jupyterhub/jupyterhub \
    --namespace $NAMESPACE  \
    --values yaml/jupyter-config.yaml


#   # This section is only required if TLS is to be enabled for the Ingress
#     tls:
#         - hosts:
#             - www.example.com
#           secretName: example-tls

# If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:
#  apiVersion: v1
#   kind: Secret
#   metadata:
#     name: example-tls
#     namespace: foo
#   data:
#     tls.crt: <base64 encoded cert>
#     tls.key: <base64 encoded key>
#   type: kubernetes.io/tls
