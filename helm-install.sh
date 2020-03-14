#!/bin/bash

#####
# The package manager for k8s.
#   https://helm.sh/

type helm >/dev/null
if [ $? == 0 ]; then
  echo "Helm: already installed."
  exit
fi

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
helm search repo stable
