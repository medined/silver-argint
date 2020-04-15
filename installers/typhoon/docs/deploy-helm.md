# Deploy Helm

The package manager for Kubernetes. Helm helps you manage Kubernetes applications — Helm Charts help you define, install, and upgrade even the most complex Kubernetes application. Charts are easy to create, version, share, and publish — so start using Helm and stop the copy-and-paste. The latest version of Helm is maintained by the CNCF - in collaboration with Microsoft, Google, Bitnami and the Helm contributor community.

NOTE: With the release of Helm 3, tiller is no longer needed.

## Links

* https://helm.sh/blog/helm-3-released/
* https://helm.sh/docs/intro/install/

## Scripted Process

```
./helm-install.sh
```

## Manual Process

* Install Helm

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
helm search repo stable
```
