# Using Spot Instances As Nodes

## Introduction

Amazon EC2 Spot Instances let you take advantage of unused EC2 capacity in the AWS cloud. Spot Instances are available at up to a 90% discount compared to On-Demand prices. 

`kops` lets you manage groups of nodes as a single unit called an instance group. This feature lets you create an instance group that consists of spot instances. When you want to run work specifically on the spot instance, a node selector tell k8s your intention.

## Configuration

* The new instance group 'spot' will look like the following. Note that `machineType` is t3.nano which is the smallest AWS instance type. You can use any size you need. Also note that `maxPrice` is set. Naturally, you'll need to set the price to something reasonable for your instance size. See https://aws.amazon.com/ec2/spot/pricing/ for information about pricing. The following settings worked for me.

```
apiVersion: kops.k8s.io/v1alpha2
kind: InstanceGroup
metadata:
  creationTimestamp: "2020-03-04T14:59:31Z"
  labels: 
    kops.k8s.io/cluster: va-oit-blue.cloud
  name: spot
spec:
  image: kope.io/k8s-1.16-debian-stretch-amd64-hvm-ebs-2020-01-17
  machineType: t3.nano
  maxPrice: "0.01"
  maxSize: 2
  minSize: 2
  nodeLabels:
    kops.k8s.io/instancegroup: spot
  role: Node
  subnets:
  - us-east-1a
```

* Run the following command to create the instancegroup. After the command is run, you'll see an editor with yaml that you'll need to customize.

```
kops create instancegroup spot --subnet us-east-1a
```

* Update the cluster. It will take several minutes for the nodes to be provisioned.

```
kops update cluster --yes
```

* When the nodes have been provisioned, you can see them with the following command.

```
kubectl get nodes -l 'kops.k8s.io/instancegroup=spot
```

## Usage

You can use the spot instance group by adding the following lines to your yaml file.

```
spec:
  nodeSelector:
      kops.k8s.io/instancegroup: spot
```
