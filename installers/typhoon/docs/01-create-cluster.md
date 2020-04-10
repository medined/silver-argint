# Create Cluster

* Install `terraform` using https://www.terraform.io/downloads.html as a guide or using any packaging method.

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

* Ignore `terraform` state files.

```bash
cat <<EOF > .gitignore
# .gitignore
*.tfstate
*.tfstate.backup
.terraform/
EOF
```

* Make sure that you have `AWS_PROFILE` and `AWS_REGION` defined. And that you have run `aws configure` in order to set the secret key values.

```bash
export AWS_PROFILE=ic1
export AWS_REGION=us-east-1
```

* Create a `providers.tf` file. Note that this file will be different for every DevSecOps person since it refers to a location in their home directory.

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

* Create a `tempest.tf` file.

```bash
PKI_PUBLIC_KEY=$(cat /$HOME/.ssh/david-va-oit-cloud-k8s.pub)

cat <<EOF > tempest.tf
module "tempest" {
  source = "git::https://github.com/poseidon/typhoon//aws/fedora-coreos/kubernetes?ref=v1.18.0"

  # AWS
  cluster_name = "tempest"
  dns_zone     = "david.va-oit.cloud"
  dns_zone_id  = "Z05543821H7X7WYIBGOOC"

  # configuration
  ssh_authorized_key = "$PKI_PUBLIC_KEY"

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

* Initial bootstrapping requires bootstrap.service be started on one controller node. Terraform uses ssh-agent to automate this step. Add your SSH private key to ssh-agent.

```bash
ssh-add $HOME/.ssh/david-va-oit-cloud-k8s.pem
ssh-add -L
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

* Export `KUBECONFIG` so that `kubectl` knows how to connect.

```
export KUBECONFIG=$HOME/.kube/configs/tempest-config
```

* View pods.

```
kubectl get pods --all-namespaces
```

## Make Your Worker Nodes Pass Target Group Healh Check

The following procedure seems to work. However, it might not be the best or even correct approach.

* SSH to each worker node.
    * Switch to super user.
    * In /etc/systemd/system/kubelet.service:
        * Change the `--healthz-port` to 10248.
        * Add `--healthz-bind-address 0.0.0.0`.
        * Run `systemctl daemon-reload`.
        * Run `systemctl restart kubelet`.
    * Use `/usr/bin/netstat -plant | grep -i kubelet | grep LISTEN | grep 10248` to check the result.
    * `exit` twice.
* In the AWS console, change the `tempest-workers-http` and `tempest-workers-https` target groups.
    * Change the health check port to 10248.
* In the AWS console, change the `tempest-worker` security group.
    * Add a rule to allow traffic on 10248.
