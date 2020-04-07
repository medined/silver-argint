#!/bin/bash

JSON_URL="https://builds.coreos.fedoraproject.org/streams/stable.json"
AMI=$(curl -s $JSON_URL | $HOME/bin/jq -r '.architectures.x86_64.images.aws.regions["us-east-1"].image')
echo "AMI: $AMI"

AWS_REGION="us-east-1"
KEY_NAME="david-va-oit-cloud-k8s"
SECURITY_GROUP_ID="sg-0a4ad278f69b3d617"  # allow-world-ssh
SUBNET_ID="subnet-02c78f939d58e2320"

PKI_PUBLIC_PEM=/tmp/david-va-oit-cloud-k8s.pem
PKI_PUBLIC_PUB=/tmp/david-va-oit-cloud-k8s.pub
SSH_USER=core

PKI_PUBLIC_KEY=$(cat $PKI_PUBLIC_PUB)

cat <<EOF > example.fcc
variant: fcos
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - $PKI_PUBLIC_PUB

systemd:
  units:
    # disable docker. podman should be used.
    - name: docker.service
      mask: true
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
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=fcos}]' \
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

echo
echo "AWS_REGION=$AWS_REGION"
echo "INSTANCE_ID=$INSTANCE_ID"
echo "PKI_PUBLIC_PEM=$PKI_PUBLIC_PEM"
echo "PUBLIC_IP=$PUBLIC_IP"
echo "SSH_USER: $SSH_USER"

# remove existing fingerprint.
ssh-keygen -R $PUBLIC_IP > /dev/null 2>&1
ssh-keyscan -H $PUBLIC_IP >> ~/.ssh/known_hosts 2>/dev/null

ssh -t -i $PKI_PUBLIC_PEM $SSH_USER@$PUBLIC_IP "sudo rpm-ostree install python libselinux-python3"

aws ec2 reboot-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
./test-ssh.sh $PUBLIC_IP $PKI_PUBLIC_PEM $SSH_USER

echo "ssh -i $PKI_PUBLIC_PEM $SSH_USER@$PUBLIC_IP"

cat <<EOF >inventory
[fcos]
$PUBLIC_IP
EOF

python3 $(which ansible-playbook) \
    -i inventory \
    --private-key $PKI_PUBLIC_PEM \
    -u $SSH_USER \
    main.playbook.yml
