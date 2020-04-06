# Introduction To Fedora CoreOS

## Words of Caution

The Fedora CoreOS is very dynamic and anything is this document might change.

## Description

Fedora CoreOS (FCOS) is an automatically updating, minimal, monolithic, container-focused operating system, designed for clusters but also operable standalone, optimized for Kubernetes but also great without it. It aims to combine the best of both CoreOS Container Linux and Fedora Atomic Host, integrating technology like Ignition from Container Linux with rpm-ostree and SELinux hardening from Project Atomic. Its goal is to provide the best container host to run containerized workloads securely and at scale.

Fedora CoreOS is an open source project associated with the Fedora Project. We are aiming for high compatibility with existing Container Linux configuration and user experience, and we expect to provide documentation and tooling to help migrate from Container Linux to Fedora CoreOS.

Fedora CoreOS (FCOS) has no install-time configuration. Every FCOS system begins with a generic disk image. For each deployment mechanism (cloud VM, local VM, bare metal), configuration can be supplied at first boot. FCOS reads and applies the configuration file with Ignition. For cloud deployments, Ignition gathers the configuration via the cloud’s user-data mechanism.

## Goal

1. Start EC2 instances using FCOS.
2. Use `kubeadm` to start Kubernetes.

## Links

* https://docs.fedoraproject.org/en-US/fedora-coreos/
* https://containerd.io/
* Unreviewed
    * https://jebpages.com/2019/02/25/installing-kubeadm-on-fedora-coreos/
    * https://www.cloudtechnologyexperts.com/kubeadm-on-aws/
    * https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/
    * https://kubernetes.io/docs/setup/production-environment/container-runtimes/

## Start EC2 Instance

```
JSON_URL="https://builds.coreos.fedoraproject.org/streams/stable.json"
AMI=$(curl -s $JSON_URL | $HOME/bin/jq -r '.architectures.x86_64.images.aws.regions["us-east-1"].image')
echo "AMI: $AMI"

AWS_REGION="us-east-1"
KEY_NAME="david-va-oit-cloud-k8s"
SECURITY_GROUP_ID="sg-0a4ad278f69b3d617"  # allow-world-ssh
SUBNET_ID="subnet-02c78f939d58e2320"

PKI_PUBLIC_KEY=$(cat /tmp/david-va-oit-cloud-k8s.pub)

cat <<EOF > example.fcc
variant: fcos
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - $PKI_PUBLIC_KEY

systemd:
  units:
    - name: healthz.service
      enabled: true
      contents: |
        [Unit]
        Description=A healthz unit!
        After=network-online.target
        Wants=network-online.target
        [Service]
        Type=forking
        KillMode=none
        Restart=on-failure
        RemainAfterExit=yes
        ExecStartPre=podman pull medined/simple-nodejs:0.0.2
        ExecStart=podman run -d --name healthz-server -p 10254:10254 medined/simple-nodejs:0.0.2
        ExecStop=podman stop -t 10 healthz-server
        ExecStopPost=podman rm healthz-server
        [Install]
        WantedBy=multi-user.target
EOF

docker pull quay.io/coreos/fcct:release
docker run -i --rm quay.io/coreos/fcct:release --pretty --strict < example.fcc > example.ign

aws ec2 run-instances \
  --associate-public-ip-address \
  --count 1 \
  --image-id $AMI \
  --instance-type t2.micro \
  --key-name $KEY_NAME \
  --region $AWS_REGION \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=fcos}]' \
  --user-data file://example.ign

ssh -i /tmp/david-va-oit-cloud-k8s.pem core@34.201.6.222

sudo tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

# This command failed. Perhaps because the change already exists.
# sudo rpm-ostree override replace https://copr-be.cloud.fedoraproject.org/results/jasonbrooks/containernetworking-cni/fedora-29-x86_64/00861706-containernetworking-plugins/containernetworking-plugins-0.7.4-1.fc29.x86_64.rpm

# This command failed.
sudo rpm-ostree install cri-o kubelet kubectl kubeadm -r

```

sudo su -
cd /etc
wget https://github.com/containerd/containerd/archive/v1.3.3.zip
unzip v1.3.3.zip
ln -s containerd-1.3.3/ containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd