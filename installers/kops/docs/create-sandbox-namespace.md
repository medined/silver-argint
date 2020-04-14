# Create sandbox Namespace

Kubernetes uses the concept of Namespace to isolate one group of resources from another. Each developer should have their own namespace. For the sake of showing a concrete example, the steps below use `sandbox` as the namespace but it is expected that you'll use a unique name.

## Scripted Process

If no namespace name is provided, the script will default to `sandbox`.

```
./namespace-create.sh <namespace name>
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

* Install ingress controller. Note that $NAMESPACE is used as a prefix. This prefix will be used in later steps and documents to help find the controller service. The ingress controller will be used later to provide access to specific services over the internet. Note that a classic ELB will be created using TCP (layer 4) to forward requests from ports 80 and 443 to some randomly-assigned internal port.

```
helm install $NAMESPACE stable/nginx-ingress --namespace $NAMESPACE
```

* Get the load balancer hostname assigned to your nginx-ingress-controller service.

```
K8S_HOSTNAME=$(kubectl get service $NAMESPACE-nginx-ingress-controller --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
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
