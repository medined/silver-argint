# Create sandbox Namespace

Kubernetes uses the concept of Namespace to isolate one group of resources from another. Each developer should have their own namespace. For the sake of showing a concrete example, the steps below use `sandbox` as the namespace but it is expected that you'll use a unique name.

## Scripted Process

If no namespace name is provided, the script will default to `sandbox`.

```
./sandbox-namespace-create.sh <namespace name>
```

## Manual Process

* Create `sandbox` namespace.

```
NAMESPACE=sandbox

cat <<EOF > yaml/namespace-$NAMESPACE.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
  labels:
    name: $NAMESPACE
EOF
kubectl create -f yaml/namespace-$NAMESPACE.yaml
```

* Set the `kubectl` context so that `sandbox` is the current namespace. Undo this action by using `default` as the namespace.

```
kubectl config set-context --current --namespace=$NAMESPACE
```

*  NOTE: Remove ingress controller steps.

* Install ingress controller. Note that `dmm` is used as a prefix.

```
helm install dmm stable/nginx-ingress --namespace $NAMESPACE
```

* Get the load balancer hostname assigned to your nginx-ingress-controller service.

```
K8S_HOSTNAME=$(kubectl get service dmm-nginx-ingress-controller --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $K8S_HOSTNAME
```

* Check that DNS has propagated using `dig`. You're looking for an ANSWER SECTION in the response. If it does not exist, wait a few minutes and try again.

```
dig NS $K8S_HOSTNAME
```

## Delete sandbox namespace

```
kubectl delete namespace $NAMESPACE
kubectl delete clusterrole dmm-nginx-ingress
kubectl delete ClusterRoleBinding dmm-nginx-ingress
```
