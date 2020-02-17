# KOPS

## Links

* https://kubernetes.io/docs/setup/production-environment/tools/kops/
* https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Steps

* Update AWS configuration file, ~/.aws/credentials. Set AWS_PROFILE in ~/.bashrc

* Create an S3 bucket for random stuff.

```
aws s3 mb s3://davidmm-0341b7d4-4de1-11ea-b20a-9f9248f37193
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
aws s3 cp ~/Downloads/va-oit-cloud.pem s3://davidmm-0341b7d4-4de1-11ea-b20a-9f9248f37193
aws s3 cp ~/Downloads/va-oit-cloud.pub s3://davidmm-0341b7d4-4de1-11ea-b20a-9f9248f37193
```

* Create the cluster configuration.

```
kops create cluster \
  --cloud=aws \
  --zones=us-east-1a \
  --ssh-public-key ~/Downloads/va-oit-cloud.pub \
  va-oit.cloud
```

* As a side note, you can delete the configuration you just created using the following command.

```
kops delete cluster --name va-oit.cloud --yes
```

* Configure the cluster.

```
kops update cluster --name va-oit.cloud --yes
    I0212 17:47:34.132763   11107 executor.go:103] Tasks: 0 done / 86 total; 44 can run
    I0212 17:47:34.761536   11107 vfs_castore.go:729] Issuing new certificate: "etcd-peers-ca-events"
    I0212 17:47:34.767536   11107 vfs_castore.go:729] Issuing new certificate: "etcd-peers-ca-main"
    I0212 17:47:34.800099   11107 vfs_castore.go:729] Issuing new certificate: "apiserver-aggregator-ca"
    I0212 17:47:34.829545   11107 vfs_castore.go:729] Issuing new certificate: "etcd-manager-ca-events"
    I0212 17:47:34.886319   11107 vfs_castore.go:729] Issuing new certificate: "etcd-manager-ca-main"
    I0212 17:47:34.988459   11107 vfs_castore.go:729] Issuing new certificate: "ca"
    I0212 17:47:35.050597   11107 vfs_castore.go:729] Issuing new certificate: "etcd-clients-ca"
    I0212 17:47:35.871092   11107 executor.go:103] Tasks: 44 done / 86 total; 24 can run
    I0212 17:47:36.608023   11107 vfs_castore.go:729] Issuing new certificate: "kube-scheduler"
    I0212 17:47:36.655417   11107 vfs_castore.go:729] Issuing new certificate: "kube-controller-manager"
    I0212 17:47:36.672219   11107 vfs_castore.go:729] Issuing new certificate: "master"
    I0212 17:47:36.673181   11107 vfs_castore.go:729] Issuing new certificate: "apiserver-proxy-client"
    I0212 17:47:36.698056   11107 vfs_castore.go:729] Issuing new certificate: "apiserver-aggregator"
    I0212 17:47:36.735899   11107 vfs_castore.go:729] Issuing new certificate: "kubelet"
    I0212 17:47:36.801997   11107 vfs_castore.go:729] Issuing new certificate: "kubelet-api"
    I0212 17:47:36.906579   11107 vfs_castore.go:729] Issuing new certificate: "kops"
    I0212 17:47:36.982832   11107 vfs_castore.go:729] Issuing new certificate: "kube-proxy"
    I0212 17:47:37.035202   11107 vfs_castore.go:729] Issuing new certificate: "kubecfg"
    I0212 17:47:37.392695   11107 executor.go:103] Tasks: 68 done / 86 total; 16 can run
    I0212 17:47:37.842009   11107 launchconfiguration.go:364] waiting for IAM instance profile "nodes.va-oit.cloud" to be ready
    I0212 17:47:37.863933   11107 launchconfiguration.go:364] waiting for IAM instance profile "masters.va-oit.cloud" to be ready
    I0212 17:47:48.307187   11107 executor.go:103] Tasks: 84 done / 86 total; 2 can run
    I0212 17:47:49.108466   11107 executor.go:103] Tasks: 86 done / 86 total; 0 can run
    I0212 17:47:49.108517   11107 dns.go:155] Pre-creating DNS records
    I0212 17:47:50.292963   11107 update_cluster.go:305] Exporting kubecfg for cluster
    kops has set your kubectl context to va-oit.cloud

    Cluster is starting.  It should be ready in a few minutes.

    Suggestions:
    * validate cluster: kops validate cluster
    * list nodes: kubectl get nodes --show-labels
    * ssh to the master: ssh -i ~/.ssh/id_rsa admin@api.va-oit.cloud
    * the admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
    * read about installing addons at: https://github.com/kubernetes/kops/blob/master/docs/addons.md.
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
