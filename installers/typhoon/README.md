# Introduction To Typhoon

NOTE: The document, and others in Typhoon installer directory, assume that you have knowledge from the Kops installer directory.

## Description

Typhoon is a minimal and free Kubernetes distribution.

* Minimal, stable base Kubernetes distribution
* Declarative infrastructure and configuration
* Free (freedom and cost) and privacy-respecting
* Practical for labs, datacenters, and clouds

Typhoon distributes upstream Kubernetes, architectural conventions, and cluster addons, much like a GNU/Linux distribution provides the Linux kernel and userspace components.

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

* Install `octant`, the client-side dashboard.

* [Deploy Ingress Controller](docs/03-deploy-ingress-controller.md)

* [Deploy Cert Manager](docs/03-deploy-cert-manager.md)

* [Deploy Service with HTTPS](docs/04-deploy-service-with-http.md)

* [Add HTTPS To Service](docs/05-add-https-to-service.md)


-----------------------------------------------------------------
-----------------------------------------------------------------

```bash
curl -o stern -L https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64
chmod +x stern
```
