# Add (or Remove) Node To Cluster

`kops` uses the concept of Instance Groups to group similar machines. This maps to auto-scaling groups in AWS.

## Links

* https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md
* https://github.com/kubernetes/kops/blob/master/docs/tutorial/working-with-instancegroups.md

## Steps

* Use `./cluster-connect.sh` to connect to the cluster that needs changing.

* List the instance groups. You should see two. We are interested in the `nodes` instance group.

```
kops get instancegroups
```

* Edit the `nodes` instance group. Change `minSize` to whatever positive number you'd like. Make sure that `maxSize` is equal to or larger than `minSize`.

```
kops edit ig nodes
```

* The instance group yaml will look like this.

```
apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: "2020-03-04T12:46:41Z"
  generation: 2
  labels: 
    kops.k8s.io/cluster: va-oit-blue.cloud
  name: nodes
spec:
  image: ami-07cce92cad14cc238
  machineType: t2.medium
  maxSize: 5
  minSize: 3
  nodeLabels:
    kops.k8s.io/instancegroup: nodes
  role: Node
  subnets:
  - us-east-1a
```

* Now update the cluster.

```
kops upgrade cluster --yes
```

* Wait a few minutes, then look at the node list.

```
kubectl get nodes
```
