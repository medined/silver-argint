#!/bin/bash

####
# This script deploys the dashboard to the current k8s cluster. The project
# is located at https://github.com/kubernetes/dashboard.

####
# Remove previous versions using this command
#   kubectl delete ns kubernetes-dashboard

# Pull the dashboard components from the kubernetes project. You can run
# apply over and over without ill effect.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc5/aio/deploy/recommended.yaml

# Create the admin-user service account.

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Create a cluser role binding.

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

POD=$(kubectl get pods \
  --namespace kubernetes-dashboard \
  -l "k8s-app=kubernetes-dashboard" \
  -o jsonpath="{.items[0].metadata.name}")

ps fx | grep "kubectl proxy --namespace kubernetes-dashboard" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "#################################"
  echo "# The proxy is already running. #"
  echo "#################################"
else
  nohup kubectl proxy --namespace kubernetes-dashboard 2>&1 &
fi

URL=http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/


# Get a login bearer token.

./get-login-token.sh
echo
echo "Copy the login token to your clipboard."
read -p "Press <ENTER> to continue."

type brave-browser > /dev/null
if [ $? == 0 ]; then
  brave-browser $URL
else
    type firefox > /dev/null
    if [ $? == 0 ]; then
        firefox $URL
    else
        type /opt/google/chrome/chrome > /dev/null
        if [ $? == 0 ]; then
            /opt/google/chrome/chrome $URL
        fi
    fi
fi
