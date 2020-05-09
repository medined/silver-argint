# Introduction To Node Selection

In Kubernetes there is are the oppposite concepts of Affinity and Anti-Affinity. Each node can be assigned a variety of labels. For example, `blue`, then when a pod is defined you can indicate that either is *should* run on `blue` or it *should not*. Realize that a set of nodes can also be given the same label.

Labels can be used for a variety of reasons. For example:

* All work for a given client should run on the same node.
* Different job classifications (unclassified, confidential, top secret) could run on a set of nodes.
* To indicate a node has a GPU.
* To indicate large memory or disk capacity.

Kubernetes implements node affinity with the `nodeSelector` and `nodeAffinity` fields in PodSpec. These fields use both pre-populated metadata or user-defined metadata.

## Assign Proper Roles To Nodes

* Get the list of nodes. Notice that the ROLES column has no values.

```bash
$HOME/bin/kubectl get nodes
```

* Depending on your cluster name, look at the node name (in the EC2 console) then use the following examples to assign roles to your nodes.

```bash
$HOME/bin/kubectl label nodes ip-10-0-95-128 node-role.kubernetes.io/master=true
$HOME/bin/kubectl label nodes ip-10-0-9-248 node-role.kubernetes.io/worker=true
```

* Get the list of nodes. Now there are values in the ROLES column.

```bash
$HOME/bin/kubectl get nodes
```

## Create RED Node.

* List the worker nodes.

```bash
$HOME/bin/kubectl get nodes --selector node-role.kubernetes.io/worker=true
```

* Assign the RED label to one of them.

```bash
$HOME/bin/kubectl label nodes ip-10-0-9-248 disktype=red
$HOME/bin/kubectl label nodes ip-10-0-63-186 disktype=red
```

* List just the RED nodes.

```bash
$HOME/bin/kubectl get nodes --selector color=RED
```

## NodeSelector: Run Pod On RED Node 

```bash
NAMESPACE=$(uuid)
$HOME/bin/kubectl create namespace $NAMESPACE

POD_NAME="nginx-$(uuid | cut -b-5)"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $NAMESPACE
  labels: 
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: red
EOF

$HOME/bin/kubectl -n $NAMESPACE get pod -o wide -w

### Look at the node the pod is running. It should be the node selected.

$HOME/bin/kubectl -n $NAMESPACE delete pod $POD_NAME
$HOME/bin/kubectl delete namespace $NAMESPACE
```
