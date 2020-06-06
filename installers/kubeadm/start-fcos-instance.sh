#!/bin/bash

type curl
if [ $? != 0 ]; then
  echo "Install curl."
  exit
fi

type jq
if [ $? != 0 ]; then
  echo "Install jq."
  exit
fi


JSON_URL="https://builds.coreos.fedoraproject.org/streams/stable.json"
AMI=$(curl -s $JSON_URL | jq -r '.architectures.x86_64.images.aws.regions["us-east-1"].image')
echo "AMI: $AMI"

AWS_REGION="us-east-1"
KEY_NAME="david-va-oit-cloud-k8s"
SECURITY_GROUP_ID="sg-0a4ad278f69b3d617"  # allow-world-ssh
SUBNET_ID="subnet-02c78f939d58e2320"
PKI_PRIVATE_PEM=/home/medined/Downloads/pem/david-va-oit-cloud-k8s.pem
PKI_PUBLIC_PUB=/home/medined/Downloads/pem/david-va-oit-cloud-k8s.pub
SSM_BINARY_DIR=/data/projects/dva/amazon-ssm-agent/bin
SSH_USER=core

if [ ! -d $SSM_BINARY_DIR ]; then
  echo "Missing directory: $SSM_BINARY_DIR"
  exit
fi

# kubeadm needs at least two CPUs"
INSTANCE_TYPE="t3.medium"

aws ec2 describe-security-groups \
  --region $AWS_REGION \
  --group-ids $SECURITY_GROUP_ID \
  --query 'SecurityGroups[0].GroupId' | grep $SECURITY_GROUP_ID

if [ $? != 0 ]; then
  echo "Missing security group: $SECURITY_GROUP_ID"
  exit
fi

aws ec2 describe-subnets \
  --region $AWS_REGION \
  --subnet-ids $SUBNET_ID \
  --query 'Subnets[0].SubnetId' | grep $SUBNET_ID

if [ $? != 0 ]; then
  echo "Missing subnet: $SUBNET_ID"
  exit
fi

# Create a public key from the pem file.
if [ -f $PKI_PUBLIC_PUB ]; then
    echo "local kops public key: Exists - $PKI_PUBLIC_PUB"
else
    ssh-keygen -y -f $PKI_PRIVATE_PEM > $PKI_PUBLIC_PUB
    echo "local kops public key: Created - $PKI_PUBLIC_PUB"
fi

PKI_PUBLIC_KEY=$(cat $PKI_PUBLIC_PUB)

cluster_dns_service_ip=10.3.0.10
cluster_domain_suffix=cluster.local

# When docker is masked (not enabled), kubeadm complains with this message:
#
# [WARNING Service-Docker]: docker service is not enabled, please run 
# 'systemctl enable docker.service'

export DHUSER="medined"
export IMAGE_NAME="healthz-service"
export IMAGE_TAG="0.0.1"
export IMAGE="$DHUSER/$IMAGE_NAME:$IMAGE_TAG"

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
    - name: docker.service
      enabled: true
EOF

echo "Pulling fcc compiler from quay.io."
docker pull quay.io/coreos/fcct:release

echo "Compiling fcc file into an ign file."
docker run -i --rm quay.io/coreos/fcct:release --pretty --strict < example.fcc > example.ign

if [ $? != 0 ]; then
  echo "ERROR: Unable to compile FCC file."
  exit 1
fi

INSTANCE_NAME="fcos-$(date +%Y%m%d%H%M%S)"

echo "Starting instance."
INSTANCE_ID=$(aws ec2 run-instances \
  --associate-public-ip-address \
  --count 1 \
  --image-id $AMI \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --region $AWS_REGION \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=ssm-installed,Value=true}]" \
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

echo "remove existing ssh fingerprint."
ssh-keygen -R $PUBLIC_IP > /dev/null 2>&1
echo "get ssh fingerprint."
ssh-keyscan -H $PUBLIC_IP >> ~/.ssh/known_hosts 2>/dev/null

# PRODUCTION NODE: In a production environment, audit
# might not be installed.

echo "install packages."
ssh -t \
  -i $PKI_PRIVATE_PEM \
  $SSH_USER@$PUBLIC_IP \
  "sudo rpm-ostree install audit conntrack ethtool golang libselinux-python3 make python setools setroubleshoot udica"

echo "reboot instance."
aws ec2 reboot-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
echo "waiting for reboot command to process"
sleep 10

./test-ssh.sh $PUBLIC_IP $PKI_PRIVATE_PEM $SSH_USER

echo "create inventory."
cat <<EOF >inventory
[fcos]
$PUBLIC_IP
EOF

echo "run playbook."
python3 $(which ansible-playbook) \
    --extra-vars "ssm_binary_dir=$SSM_BINARY_DIR" \
    -i inventory \
    --private-key $PKI_PRIVATE_PEM \
    -u $SSH_USER \
    main.playbook.yml

echo "display variables."
cat <<EOF
AWS_REGION=$AWS_REGION
INSTANCE_ID=$INSTANCE_ID
PKI_PRIVATE_PEM=$PKI_PRIVATE_PEM
PUBLIC_IP=$PUBLIC_IP
SSH_USER=$SSH_USER
EOF

echo
echo "ssh -i $PKI_PRIVATE_PEM $SSH_USER@$PUBLIC_IP"
echo
