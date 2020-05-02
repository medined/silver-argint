# Create Cluster

Typhoon is a Kubernetes cluster provisioner tool. After installation a small bit of configuration is needed, then let it do the heavy lifting.

## Install and Configure Typhoon Software

* Install `terraform` using https://www.terraform.io/downloads.html as a guide or use any packaging method.

* Add the `terraform-provider-ct` plugin binary.

```bash
mkdir -p ~/.terraform.d/plugins
wget https://github.com/poseidon/terraform-provider-ct/releases/download/v0.5.0/terraform-provider-ct-v0.5.0-linux-amd64.tar.gz
tar xzf terraform-provider-ct-v0.5.0-linux-amd64.tar.gz
mv terraform-provider-ct-v0.5.0-linux-amd64/terraform-provider-ct ~/.terraform.d/plugins/terraform-provider-ct_v0.5.0
rm -rf terraform-provider-ct-v0.5.0-linux-amd64.tar.gz terraform-provider-ct-v0.5.0-linux-amd64
```

* Connect to your `installers/typhoon` directory.

```bash
cd installers/typhoon
```

* Ignore `terraform` state files. These files are where Typhoon stores information about the provision process and your cluster. `providers.tf` is ignored because it is different for each DevSecOps person.

```bash
cat <<EOF > .gitignore
providers.tf
*.tfstate
*.tfstate.backup
.terraform/
EOF
```

* Make sure that you have `AWS_PROFILE` and `AWS_REGION` defined. And that you have run `aws configure` in order to set the secret key values. I place these commands in my `$HOME/.bashrc` so they are always available.

```bash
export AWS_PROFILE=ic1
export AWS_REGION=us-east-1
```

* Define the public key that will be used to access the cluster using SSH. This should be the public key from an EC2 Key Pair.

```bash
export PKI_PUBLIC_KEY=$(cat /$HOME/.ssh/david-va-oit-cloud-k8s.pub)
```

* Create a `providers.tf` file. Note that this file will be different for every DevSecOps person since it refers to a location in their home directory. It might not look different below, but the $HOME gets interpreted.

```bash
cat <<EOF > providers.tf
provider "aws" {
  version                 = "2.53.0"
  region                  = "$AWS_REGION"
  shared_credentials_file = "$HOME/.config/aws/credentials"
}

provider "ct" {
  version = "0.5.0"
}
EOF
```

* Create a `tempest.tf` file. It is named after the cluster name. If you want a different name, change this file name as well. The `ref` option pulls that tag from Github. Make sure to change the following:

  * cluster_name
  * dns_zone
  * dns_zone_id

```bash
cat <<EOF > tempest.tf
locals {
  ssh_authorized_key = "ssh-rsa ..."
}

output "ssh_authorized_key" {
  value = "${local.ssh_authorized_key}"
}

module "tempest" {
  source = "git::https://github.com/poseidon/typhoon//aws/fedora-coreos/kubernetes?ref=v1.18.1"

  # AWS
  cluster_name = "tempest"
  dns_zone     = "david.va-oit.cloud"
  dns_zone_id  = "Z05543821H7X7WYIBGOOC"

  # configuration
  ssh_authorized_key = "${local.ssh_authorized_key}"

  # optional
  worker_count = 2
  worker_type  = "t3.small"
}

# Obtain cluster kubeconfig
resource "local_file" "kubeconfig-tempest" {
  content  = module.tempest.kubeconfig-admin
  filename = "$HOME/.kube/configs/tempest-config"
}
EOF
```

* Terraform uses ssh-agent to automate this step. Add your SSH private key to ssh-agent. This command can also be added to your `$HOME/.bashrc` file.

```bash
ssh-add $HOME/.ssh/david-va-oit-cloud-k8s.pem
```

* Initialize `terraform`.

```bash
terraform init
```

* Plan the resources.

```bash
terraform plan
```

* Create the cluster.

```bash
terraform apply
```

* Export `KUBECONFIG` so that `kubectl` knows how to connect. Another great command to add to your `$HOME/.bashrc` file.

```bash
export KUBECONFIG=$HOME/.kube/configs/tempest-config
```

* View nodes. Notice that the ROLES column is empty.

```bash
$HOME/bin/kubectl get nodes
```

* Assign roles to your nodes that you'll see in the `get nodes` command.

```bash
$HOME/bin/kubectl label nodes --selector=node.kubernetes.io/master= node-role.kubernetes.io/master=true

$HOME/bin/kubectl label nodes --selector=node.kubernetes.io/node= node-role.kubernetes.io/worker=true
```

* View pods.

```bash
$HOME/bin/kubectl get pods --all-namespaces
```

* Find the public IP of the master (AKA controller) node, then SSH to it.

```bash
PKI_PEM=/home/medined/Downloads/pem/david-va-oit-cloud-k8s.pem
PUBLIC_IP=3.235.132.234
ssh -i $PKI_PEM core@$PUBLIC_IP
```

* Change to the super user.

```bash
sudo su -
```

* Add the following as one of the parameters to the `kube-apiserver` command. As soon as you save the file, the `apiserver` pod will be restarted. This will cause connection errors because the api server stops responding. This is normal. Wait a few minutes and the pod will restart and start responds to requests.

```
--enable-admission-plugins=AlwaysPullImages,LimitRanger,TaintNodesByCondition,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,PersistentVolumeClaimResize,CertificateApproval,CertificateSigning,CertificateSubjectRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,NamespaceLifecycle,ServiceAccount,Priority,RuntimeClass,ResourceQuota
```


## A Note About Unhealthy Instances

The cluster has one network load balancer that accepts requests from the internet on ports 80, 443, and 6443. Each port has its own target group:

* tempest-controllers - master node - has healthy instances.
* tempest-http - worker nodes - has unhealthy instances.
* tempest-https - worker nodes - has unhealthy instances.

The instances are unhealthy because there is no process responding to the health checks. This makes sense because no ingress controller has been created yet. It is the job of the ingress controller to respond to the health check. Look in the `ingress-controller` directory for the manifests.
