# Introduction To Typhoon

NOTE: The document, and others in Typhoon installer directory, assume that you have knowledge from the Kops installer directory.

## Description

Typhoon is a minimal and free Kubernetes distribution.

* Minimal, stable base Kubernetes distribution
* Declarative infrastructure and configuration
* Free (freedom and cost) and privacy-respecting
* Practical for labs, datacenters, and clouds

Typhoon distributes upstream Kubernetes, architectural conventions, and cluster addons, much like a GNU/Linux distribution provides the Linux kernel and userspace components.

After getting a cluster running, read [order of scripts](docs/00-order-of-scripts.md).

## Links

* https://typhoon.psdn.io/
* https://typhoon.psdn.io/fedora-coreos/aws/

## Order of Operations

* [Create Cluster](docs/01-create-cluster.md)

* Install `helm`.

```bash
./scripts/helm-install.sh
```

* Install `krew`.

```bash
./scripts/krew-install.sh
```

* Install dashboard and start proxy in background. Or see [Deploy Dashboard](docs/02-deploy-dashboard.md)

```bash
./dashboard-proxy-start.sh
```

* Create a namespace.

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: $NAMESPACE
    labels:
        name: $NAMESPACE
EOF
```

* Set the `kubectl` context so that $NAMESPACE is the current namespace. Undo this action by using `default` as the namespace.

```bash
kubectl config set-context --current --namespace=$NAMESPACE
```

* NOT WORKING! Install nginx-ingress.

```bash
pushd /tmp > /dev/null
git clone https://github.com/poseidon/typhoon.git
cd typhoon
kubectl apply -R -f addons/nginx-ingress/aws
popd
```

* [Deploy Cert Manager](docs/03-deploy-cert-manager.md)


=================================================================
=================================================================
=================================================================
=================================================================
=================================================================
=================================================================
=================================================================
=================================================================
=================================================================


./istio-install.sh -f $CONFIG_FILE $NAMESPACE

./create-vanity-url.sh -f $CONFIG_FILE $NAMESPACE registry
# pause until the dig answer shows AWS information.
./custom-docker-registry-install.sh -f $CONFIG_FILE $NAMESPACE

./create-vanity-url.sh -f $CONFIG_FILE $NAMESPACE jenkins
# pause until the dig answer shows AWS information.
./jenkins-helm-set-admin-password-secret.sh $NAMESPACE $JENKINS_ADMIN_PASSWORD
./jenkins-helm-install.sh -f $CONFIG_FILE $NAMESPACE
./jenkins-helm-check.sh $NAMESPACE
./jenkins-proxy-start.sh $NAMESPACE
