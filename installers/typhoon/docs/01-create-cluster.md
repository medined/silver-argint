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
export PKI_PUBLIC_KEY=$(cat $HOME/Downloads/pem/david-va-oit-cloud-k8s.pub)
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
  source = "git::https://github.com/poseidon/typhoon//aws/fedora-coreos/kubernetes?ref=v1.18.3"

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
ssh-add $HOME/Downloads/pem/david-va-oit-cloud-k8s.pem
```

* Initialize `terraform`.

```bash
terraform init
```

* Plan the resources.

```bash
terraform plan
```

* Create the cluster. This can take up to ten minutes, please be patient.

```bash
terraform apply
```

* Export `KUBECONFIG` so that `kubectl` knows how to connect. Another great command to add to your `$HOME/.bashrc` file.

```bash
export KUBECONFIG=$HOME/.kube/configs/tempest-config
```

* View nodes. Notice that the ROLES column is empty. If a worker node is not ready, it is OK to terminate it. A few minutes later, a new node will be provisioned.

```bash
kubectl get nodes
```

* Assign roles to your nodes that you'll see in the `get nodes` command. You can re-run this command if the nodes change.

```bash
kubectl label nodes --selector=node.kubernetes.io/master= node-role.kubernetes.io/master=true
kubectl label nodes --selector=node.kubernetes.io/node= node-role.kubernetes.io/worker=true
```

* View pods.

```bash
kubectl get pods --all-namespaces
```

## Add Initial Pod Security Policies

Learning about pod security policies is a big topic. We won't cover it here other than to say that before turning the PodSecurityPolicy admission controller, pod security policies need to be in place so that pods in the kube-system namespace can start. That's what the following command does, it provides a bare minimum set of policies needed to start the apiserver pod.

Note that the restricted clusterrole as *zero* rules. If you want normal users to perform commands, you'll need to explicitly create rules.

A summary of the `restricted` PSP.

* Enable read-only root filesystem
* Enable security profiles
* Prevent host network access
* Prevent privileged mode
* Prevent root privileges
* Whitelist read-only host path
* Whitelist volume types

Some things to remember.

* Don’t write data to your pod unless it is setup with an emptyVolume mount
* Cluster-wide permissions should generally be avoided in favor of namespace-specific permissions.


```bash
kubectl apply -f - <<EOF
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: privileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: "*"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
spec:
  privileged: true
  allowPrivilegeEscalation: true
  allowedCapabilities: ['*']
  volumes: ['*']
  hostNetwork: true
  hostIPC:     true
  hostPID:     true
  hostPorts: [{ min: 0, max: 65535 }]
  runAsUser:          { rule: RunAsAny }
  seLinux:            { rule: RunAsAny }
  supplementalGroups: { rule: RunAsAny }
  fsGroup:            { rule: RunAsAny }
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default,runtime/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'runtime/default'
spec:
  # Restrict pods to just a /pod directory and ensure that it is read-only.
  allowedHostPaths:
    - pathPrefix: /pod
      readOnly: true

  privileged: false
  allowPrivilegeEscalation: false
  # This is redundant with non-root + disallow privilege escalation, but we can provide it for defense in depth.
  requiredDropCapabilities: [ALL]
  readOnlyRootFilesystem: true

  hostNetwork: false
  hostIPC:     false
  hostPID:     false

  runAsUser:
    # Require the container to run without root privileges.
    rule: MustRunAsNonRoot

  seLinux:
    # Assume nodes are using AppArmor rather than SELinux.
    rule: RunAsAny

  # Forbid adding the root group.
  supplementalGroups:
    rule: MustRunAs
    ranges: [{ min: 1, max: 65535 }]

  # Forbid adding the root group.
  fsGroup:
    rule: MustRunAs
    ranges: [{ min: 1, max: 65535 }]

  # Allow core volume types. Assume that persistentVolumes set up by the cluster admin are safe to use.
  volumes:
    - configMap
    - downwardAPI
    - emptyDir
    - persistentVolumeClaim
    - projected
    - secret
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: psp:privileged
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
rules:
- apiGroups: ['extensions']
  resources: ['podsecuritypolicies']
  verbs:     ['use']
  resourceNames:
  - privileged
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: psp:restricted
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: default:restricted
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind:     ClusterRole
  name:     psp:restricted
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind:     Group
  name:     system:authenticated
- apiGroup: rbac.authorization.k8s.io
  kind:     Group
  name:     system:serviceaccounts
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default:privileged
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind:     ClusterRole
  name:     psp:privileged
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind:     Group
  name:     system:masters
- apiGroup: rbac.authorization.k8s.io
  kind:     Group
  name:     system:nodes
- apiGroup: rbac.authorization.k8s.io
  kind:     Group
  name:     system:serviceaccounts:kube-system
EOF
```

## ClusterRole Suggestions

The `psp:restricted` cluster role can't do anthing. Consider creating a `psp:developers` role that has permissions within specific namespaces.

* Ability To List Secrets

```
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["list"]
```

## Enabling Admission Controllers

* Find the public IP of the master (AKA controller) node, then SSH to it.

```bash
CONTROLLER_IP=$(aws ec2 describe-instances --region $AWS_REGION --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='tempest-controller-0'" --query 'Reservations[].Instances[].PublicIpAddress' --output text)

PKI_PEM=/home/medined/Downloads/pem/david-va-oit-cloud-k8s.pem
ssh -i $PKI_PEM core@$CONTROLLER_IP
```

* Change to the super user.

```bash
sudo su -
```

* Edit /etc/kubernetes/manifests/kube-apiserver.yaml by adding the following as one of the parameters to the `kube-apiserver` command. As soon as you save the file, the `apiserver` pod will be restarted. This will cause connection errors because the api server stops responding. This is normal. Wait a few minutes and the pod will restart and start responds to requests. Check the command using `octant` or another technique. If you don't see the admission controllers in the command, resave the file to restart the pod.

```
--enable-admission-plugins=AlwaysPullImages,LimitRanger,TaintNodesByCondition,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,PersistentVolumeClaimResize,CertificateApproval,CertificateSigning,CertificateSubjectRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,NamespaceLifecycle,ServiceAccount,Priority,RuntimeClass,ResourceQuota,PodSecurityPolicy
```

* You can run the following command to ensure that `kubelet` started properly.

```bashrc
systemctl status kubelet
```

## A Note About Unhealthy Instances

The cluster has one network load balancer that accepts requests from the internet on ports 80, 443, and 6443. Each port has its own target group:

* tempest-controllers - master node - has healthy instances.
* tempest-http - worker nodes - has unhealthy instances.
* tempest-https - worker nodes - has unhealthy instances.

The instances are unhealthy because there is no process responding to the health checks. This makes sense because no ingress controller has been created yet. It is the job of the ingress controller to respond to the health check. Look in the `ingress-controller` directory for the manifests.
