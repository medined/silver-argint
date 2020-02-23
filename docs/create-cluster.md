# KOPS

## Links

* https://kubernetes.io/docs/setup/production-environment/tools/kops/
* https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Steps

* Update AWS configuration file, ~/.aws/credentials. Set AWS_PROFILE in ~/.bashrc

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

* Specify a cluster name.

```
export NAME=va-oit.cloud
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
chmod 600 ~/Downloads/$NAME.pem
ssh-keygen -y -f ~/Downloads/$NAME.pem > ~/Downloads/$NAME.pub
aws s3 cp ~/Downloads/$NAME.pem s3://$S3_RANDOM
aws s3 cp ~/Downloads/$NAME.pub s3://$S3_RANDOM
```

* Create the cluster configuration.

```
kops create cluster \
  --cloud=aws \
  --zones=us-east-1a \
  --ssh-public-key ~/Downloads/$NAME.pub \
  $NAME
```

* As a side note, you can delete the configuration you just created using the following command.

```
kops delete cluster --name va-oit.cloud --yes
```

* Configure the cluster.

```
kops update cluster --name $NAME --yes
```

* Wait several minutes for the EC2 instances to become active. The validate the cluster is running.

```
kops validate cluster
```

* You can list the nodes.

```
kubectl get nodes
```

* You can SSH to the master node but I don't recommend this. If you are not using Debian as the base operating system, you might need to use a different user than `admin`.

```
ssh -i ~/Downloads/$NAME.pem admin@api.$NAME
``

### Visit Cluster Home Page

* Learn cluster URL.

```
kubectl cluster-info
```

* Learn cluster admin password.

```
kubectl config view --minify --output jsonpath="{.users[?(@.user.username=='admin')].user.password}";echo
```

* Visit the cluster URL using the `admin` username and the revealed password.


### Dashboard Deployment

* Appy the manifest.

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

* Get a login bearer token. Copy the token and paste it into the login screen. You could also run `get-login-token.sh`.

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

## Notes

* https://www.oit.va.gov/library/recurring/edp/ - the team behind the kubernetes research.

## Research

* https://medium.com/faun/how-to-setup-a-perfect-kubernetes-cluster-using-kops-in-aws-b616bdfae013 - cluster with 3 master nodes and 2 worker nodes with 1 AWS On-demand instance and 1 AWS Spot instance within a private topology with multi-availability zones deployment.
* https://garden.io/ - garden automates the repetitive parts of your workflow to make developing for Kubernetes and cloud faster and easier.
* https://okteto.com/ - Development platform for Kubernetes applications. Build better applications by developing and testing your code directly in Kubernetes.
* https://blog.alexellis.io/a-bit-of-istio-before-tea-time/ - Istio demo up and running with a public IP directly to your laptop.
* https://www.youtube.com/watch?v=8JbGfNNG1mQ - kubernetes team live stream
* https://github.com/kubernetes-sigs/kubespray - Deploy a Production Ready Kubernetes Cluster
* https://kind.sigs.k8s.io/ - running local Kubernetes clusters using Docker container “nodes”.
