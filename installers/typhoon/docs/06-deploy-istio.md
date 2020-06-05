# Deploy Istio

Connect, secure, control, and observe services.

Istio's sidecar injection process requires that its containers be privileged. This
need conflicts with the pod security polices in place. See the "workaround" section
below.

## Install Istio

Run the following:

```bash
./scripts/istio-install.sh
```

## View Kiali Dashboard

* Visit the Kiali dashboard. Use admin/admin for credentials.

```bash
istioctl dashboard kiali
```

## Autmatically Enabling Istio In A Namespace.

Each namespace needs to have Istion enabled in it. However, this does not work
because privileged containers are not allowed unless started by the superuser.

```bash
kubectl label namespace default istio-injection=enabled
```

## Manually Enabling Istio In A Namespace.

If you have a manifest yaml file, you this as your template.

```bash
istioctl kube-inject -f /tmp/bookinfo.yaml | \
  sed 's/privileged: false/privileged: true/' | \
  sed 's/allowPrivilegeEscalation: false/allowPrivilegeEscalation: true/' | \
  kubectl --namespace bookinfo apply -f -
```

Otherwise, use the following:

```bash
kubectl --namespace todo get deployment database -o yaml | \
  istioctl kube-inject -f - | \
  sed 's/privileged: false/privileged: true/' | \
  sed 's/allowPrivilegeEscalation: false/allowPrivilegeEscalation: true/' | \
  kubectl --namespace todo apply -f -
```
