# Highly Available Kubernetes Cluster

This article shows how to create a multi-master, multi-node cluster.

## Links

* https://github.com/kubernetes/kops/blob/master/docs/examples/coreos-kops-tests-multimaster.md

## Steps

* Update AWS configuration file, ~/.aws/credentials. Set AWS_PROFILE in ~/.bashrc

* Read https://github.com/kubernetes/kops/blob/master/docs/examples/basic-requirements.md and follow whatever steps are appropriate.

* Create an S3 bucket for random stuff.

```
export S3_RANDOM=davidmm-0341b7d4-4de1-11ea-b20a-9f9248f37193
aws s3 mb s3://$S3_RANDOM
```

* Register a domain using Route53. For example, using va-oit.cloud. Wait until the domain has been provisioned and you can find it using a command like the following.

```
dig NS va-oit.cloud
```

* Create an S3 bucket to store the cluster's state. Who ever has access to this bucket can do bad things to the cluster. Therefore, pay attention to its security configuration. Don't use periods in the bucket name.

```
aws s3 mb s3://va-oit-cloud--16d7b802-4de6-11ea-924b-ef8fcd6cbcb5
```

* Export an environment variable to let `kops` know where to store its state. You could add this variable to your ~/.bashrc file if you are only working with one cluster or if you want one bucket to hold the states of multiple clusters.

```
export KOPS_STATE_STORE=s3://va-oit-cloud--16d7b802-4de6-11ea-924b-ef8fcd6cbcb5
```

* Specify a cluster name. This example uses `gossip` DNS which requres a suffix of `k8s.local`.

```
export NAME=ha-va-oit.k8s.local
```

* Install `kubectl`.

```
export STABLE_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO https://storage.googleapis.com/kubernetes-release/release/$STABLE_VERSION/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

* Install auto-completion package.

```
sudo apt-get install bash-completion
```

* Enable kubectl auto-completion when your bash shell starts.

```
echo 'source <(kubectl completion bash)' >>~/.bashrc
```

* Install `kops`.

```
export KOPS_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -LO https://github.com/kubernetes/kops/releases/download/$KOPS_VERSION/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops
```

* Check installation.

```
kubectl version --client
kops version
```

* Create an AWS EC2 key pair. For example, it could be called va-oit-cloud. Then copy the file to S3 for safekeeping. Note that you should lock down the permissions as well. The last thing to do is generate a public key from the PEM file (the private key)

```
chmod 600 ~/Downloads/va-oit-cloud.pem
ssh-keygen -y -f ~/Downloads/va-oit-cloud.pem > ~/Downloads/va-oit-cloud.pub
aws s3 cp ~/Downloads/va-oit-cloud.pem s3://$S3_RANDOM
aws s3 cp ~/Downloads/va-oit-cloud.pub s3://$S3_RANDOM
```

* Get the CoreOS AMI id.

```
COREOS_AMI=$(curl -s https://coreos.com/dist/aws/aws-stable.json | jq -r '.["us-east-1"].hvm')
echo $COREOS_AMI
```

* Create the cluster configuration.

```
kops create cluster \
  --cloud=aws \
  --ssh-public-key ~/Downloads/va-oit-cloud.pub \
  --master-zones=us-east-1a,us-east-1b,us-east-1c \
  --zones=us-east-1a,us-east-1b,us-east-1c \
  --node-count=2 \
  --image $COREOS_AMI \
  $NAME
```

* As a side note, you can delete the configuration you just created using the following command.

```
kops delete cluster --name $NAME --yes
```

* Deploy the cluster. Wait for the EC2 instances to become available after running this command. It should not take more than five minutes.

```
kops update cluster --name $NAME --yes
```

* As a side note, you can delete the configuration you just created using the following command.

```
kops delete cluster --name $NAME --yes
```


* Validate the cluster. If you see an `i/o timeout` the EC2 instances are probably not yet available. Wait some more. If 15 minutes goes by and you still can't validate, something is wrong. Good luck.

```
kops validate cluster
```

* View the nodes. For a more succinct list, don't show labels.

```
kubectl get nodes --show-labels
```

* View the pods. Since the cluster is brand-new, the `default` namespace has no pods, so check out a different namespace.

```
kubectl get pods --namespace kube-system
```

* Deploy the dashboard.

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

* Create the admin-user service account.

```
cat <<EOF > yaml/dashboard-adminuser.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
kubectl apply -f yaml/dashboard-adminuser.yaml
```

* Create a cluser role binding.

```
cat <<EOF > yaml/dashboard-adminuser-clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
kubectl apply -f yaml/dashboard-adminuser-clusterrolebinding.yaml
```

* Get a login bearer token. Copy the token and paste it into the login screen.

```
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

* Start the proxy. This forwards local http requests to the remote cluster.

```
kubectl proxy
```

* Visit the following link to see the dashboard.

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```
