#!/bin/bash

JSON_URL="https://builds.coreos.fedoraproject.org/streams/stable.json"
AMI=$(curl -s $JSON_URL | $HOME/bin/jq -r '.architectures.x86_64.images.aws.regions["us-east-1"].image')
echo "AMI: $AMI"

AWS_REGION="us-east-1"
KEY_NAME="david-va-oit-cloud-k8s"
SECURITY_GROUP_ID="sg-0a4ad278f69b3d617"  # allow-world-ssh
SUBNET_ID="subnet-02c78f939d58e2320"

# Add this to tempest worker manually.
SECURITY_GROUP_ID="sg-003bc1ae0f21e24b8"  # tempest-worker
SUBNET_ID="subnet-0e9037577a97a484a"


PKI_PUBLIC_PEM=/$HOME/.ssh/david-va-oit-cloud-k8s.pem
PKI_PUBLIC_PUB=/$HOME/.ssh/david-va-oit-cloud-k8s.pub
SSH_USER=core

PKI_PUBLIC_KEY=$(cat $PKI_PUBLIC_PUB)

cluster_dns_service_ip=10.3.0.10
cluster_domain_suffix=cluster.local

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
    # disable docker. podman should be used.
    - name: docker.service
      mask: true
    - name: wait-for-dns.service
      enabled: true
      contents: |
        [Unit]
        Description=Wait for DNS entries
        Before=kubelet.service
        [Service]
        Type=oneshot
        RemainAfterExit=true
        ExecStart=/bin/sh -c 'while ! /usr/bin/grep '^[^#[:space:]]' /etc/resolv.conf > /dev/null; do sleep 1; done'
        [Install]
        RequiredBy=kubelet.service
    - name: kubelet.service
      enabled: true
      contents: |
        [Unit]
        Description=Kubelet via Hyperkube (System Container)
        Wants=rpc-statd.service
        [Service]
        ExecStartPre=/bin/mkdir -p /etc/kubernetes/cni/net.d
        ExecStartPre=/bin/mkdir -p /etc/kubernetes/manifests
        ExecStartPre=/bin/mkdir -p /opt/cni/bin
        ExecStartPre=/bin/mkdir -p /var/lib/calico
        ExecStartPre=/bin/mkdir -p /var/lib/kubelet/volumeplugins
        ExecStartPre=/usr/bin/bash -c "grep 'certificate-authority-data' /etc/kubernetes/kubeconfig | awk '{print $2}' | base64 -d > /etc/kubernetes/ca.crt"
        ExecStartPre=-/usr/bin/podman rm kubelet
        ExecStart=/usr/bin/podman run --name kubelet \
          --privileged \
          --pid host \
          --network host \
          --volume /etc/kubernetes:/etc/kubernetes:ro,z \
          --volume /usr/lib/os-release:/etc/os-release:ro \
          --volume /etc/ssl/certs:/etc/ssl/certs:ro \
          --volume /lib/modules:/lib/modules:ro \
          --volume /run:/run \
          --volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
          --volume /sys/fs/cgroup/systemd:/sys/fs/cgroup/systemd \
          --volume /etc/pki/tls/certs:/usr/share/ca-certificates:ro \
          --volume /var/lib/calico:/var/lib/calico:ro \
          --volume /var/lib/docker:/var/lib/docker \
          --volume /var/lib/kubelet:/var/lib/kubelet:rshared,z \
          --volume /var/log:/var/log \
          --volume /var/run/lock:/var/run/lock:z \
          --volume /opt/cni/bin:/opt/cni/bin:z \
          quay.io/poseidon/kubelet:v1.18.0 \
          --anonymous-auth=false \
          --authentication-token-webhook \
          --authorization-mode=Webhook \
          --cgroup-driver=systemd \
          --cgroups-per-qos=true \
          --enforce-node-allocatable=pods \
          --client-ca-file=/etc/kubernetes/ca.crt \
          --cluster_dns=${cluster_dns_service_ip} \
          --cluster_domain=${cluster_domain_suffix} \
          --cni-conf-dir=/etc/kubernetes/cni/net.d \
          --exit-on-lock-contention \
          --healthz-port=0 \
          --kubeconfig=/etc/kubernetes/kubeconfig \
          --lock-file=/var/run/lock/kubelet.lock \
          --network-plugin=cni \
          --node-labels=node.kubernetes.io/node \
          %{~ for label in split(",", node_labels) ~}
          --node-labels=${label} \
          %{~ endfor ~}
          --pod-manifest-path=/etc/kubernetes/manifests \
          --read-only-port=0 \
          --volume-plugin-dir=/var/lib/kubelet/volumeplugins
        ExecStop=-/usr/bin/podman stop kubelet
        Delegate=yes
        Restart=always
        RestartSec=10
        [Install]
        WantedBy=multi-user.target
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

echo "Pulling fcc compiler from quay.io."
docker pull quay.io/coreos/fcct:release

echo "Compiling fcc file into an ign file."
docker run -i --rm quay.io/coreos/fcct:release --pretty --strict < example.fcc > example.ign

INAME="fcos-$(date +%Y%m%d%H%M%S)"

echo "Starting instance."
INSTANCE_ID=$(aws ec2 run-instances \
  --associate-public-ip-address \
  --count 1 \
  --image-id $AMI \
  --instance-type t2.micro \
  --key-name $KEY_NAME \
  --region $AWS_REGION \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INAME}]" \
  --user-data file://example.ign \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Waiting for instance."
aws ec2 wait system-status-ok --instance-ids $INSTANCE_ID --region $AWS_REGION
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID --region $AWS_REGION

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --output text \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --region $AWS_REGION)

# remove existing fingerprint.
ssh-keygen -R $PUBLIC_IP > /dev/null 2>&1
ssh-keyscan -H $PUBLIC_IP >> ~/.ssh/known_hosts 2>/dev/null

TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:506315921615:targetgroup/tempest-workers-http/b5a2dbf61b2c777a"

aws elbv2 register-targets \
  --region $AWS_REGION \
  --target-group-arn $TARGET_GROUP_ARN \
  --targets Id=$INSTANCE_ID

# ssh -t -i $PKI_PUBLIC_PEM $SSH_USER@$PUBLIC_IP "sudo rpm-ostree install python libselinux-python3"

# aws ec2 reboot-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
# ./test-ssh.sh $PUBLIC_IP $PKI_PUBLIC_PEM $SSH_USER

echo "ssh -i $PKI_PUBLIC_PEM $SSH_USER@$PUBLIC_IP"

# cat <<EOF >inventory
# [fcos]
# $PUBLIC_IP
# EOF

# python3 $(which ansible-playbook) \
#     -i inventory \
#     --private-key $PKI_PUBLIC_PEM \
#     -u $SSH_USER \
#     main.playbook.yml

echo "polling to see when instance is healthy or unhealthy"
RESULT=1 # 0 upon success
TIMEOUT=30 # number of iterations (5 minutes?)
while :; do 
    status=$(aws elbv2 describe-target-health \
      --output text \
      --query 'TargetHealthDescriptions[0].TargetHealth.State' \
      --region $AWS_REGION \
      --target-group-arn $TARGET_GROUP_ARN \
      --targets Id=$INSTANCE_ID)

    if [ "$status" == "healthy" ]; then
        echo "healthy"
        break
    fi
    if [ "$status" == "unhealthy" ]; then
        echo "unhealthy"
        break
    fi
    TIMEOUT=$((TIMEOUT-1))
    if [ $TIMEOUT -eq 0 ]; then
        echo "timed out"
    fi
    echo "waiting..."
    sleep 10
done


cat <<EOF
AWS_REGION=$AWS_REGION
INSTANCE_ID=$INSTANCE_ID
PKI_PUBLIC_PEM=$PKI_PUBLIC_PEM
PUBLIC_IP=$PUBLIC_IP
SSH_USER=$SSH_USER
TARGET_GROUP_ARN=$TARGET_GROUP_ARN
EOF

