# Deploy Public Docker Registry

## Links

* https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/

## Steps

* Get the external IP assigned to your nginx-ingress-controller service.

```
K8S_IP=$(kubectl get svc -n kube-system -o jsonpath='{.items[0].spec.clusterIP}')
echo $K8S_IP
```

* Using Route53, create an A record pointing to the K8S_IP. For example, dmm.va-oit.cloud. Wait a few minutes for the DNS change to propagate.

* Install certificate manager based on Let's Encrypt. This creates Secrets and Custom Resource Definitions.

```
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --version v0.13.0 --namespace kube-system
```

* Create sandbox namespace.

```
cat <<EOF > yaml/namespace-sandbox.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sandbox
  labels:
    name: sandbox
EOF
kubectl create -f yaml/namespace-sandbox.yaml
```

* Create Issuer.

```
cat <<EOF > yaml/issue-sandbox.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: ca-issuer
  namespace: sandbox
spec:
  ca:
    secretName: ca-key-pair
EOF
kubectl create -f yaml/issue-sandbox.yaml
```

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://docs.cert-manager.io/en/latest/reference/issuers.html

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://docs.cert-manager.io/en/latest/reference/ingress-shim.html
