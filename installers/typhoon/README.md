# Introduction To Typhoon

NOTE: The document, and others in Typhoon installer directory, assume that you have knowledge from the Kops installer directory.

## Failure

The Target Group health check is not working. I tried to add a health check service to the worker.yaml typhoon file which does start up and respond to locahost:10254/healthz but the service is not responding outside of the instance. I don't know why.

Not now, Typhoon is not an option.

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



curl -o $HOME/bin/stern -L https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64
chmod +x $HOME/bin/stern


ps auxwww


How To Make Your Worker Nodes Pass Target Group Healh Check

* SSH to each worker node.
    * Switch to super user.
    * In /etc/systemd/system/kubelet.service:
        * Change the `--healthz-port` to 10248.
        * Add `--healthz-bind-address 0.0.0.0`.
        * Run `systemctl daemon-reload`.
        * Run `systemctl restart kubelet`.
    * Use `/usr/bin/netstat -plant | grep -i kubelet | grep LISTEN | grep 10248` to check the result.

tcp6       0      0 :::10248                :::*                    LISTEN      144658/kubelet      

    * `exit` twice.
* In the AWS console, change the `tempest-workers-http` and `tempest-workers-https` target groups.
    * Change the health check port to 10248.
* In the AWS console, change the `tempest-worker` security group.
    * Add a rule to allow traffic on 10248.
