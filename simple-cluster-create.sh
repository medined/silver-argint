#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: -f [configuration file]"
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

ENV_FILE=$2
source $ENV_FILE

if [ -z $AWS_ACCESS_KEY_ID ]; then
  echo "ERROR: Missing environment variable: AWS_ACCESS_KEY_ID"
  exit
fi
if [ -z $AWS_SECRET_ACCESS_KEY ]; then
  echo "ERROR: Missing environment variable: AWS_SECRET_ACCESS_KEY"
  exit
fi
if [ -z $AWS_REGION ]; then
  echo "ERROR: Missing environment variable: AWS_REGION"
  exit
fi
if [ -z $AWS_ZONE ]; then
  echo "ERROR: Missing environment variable: AWS_ZONE"
  exit
fi
if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  exit
fi

# Does a bin directory exist in the user's home directory? This is where
# downloaded software will be placed.

[ -d $HOME/bin ] || mkdir $HOME/bin

if [ -f $HOME/bin/kubectl ]; then
    echo "kubectl: Installed"
else
    echo "kubectl: Installing"
    STABLE_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    curl -L -o $HOME/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$STABLE_VERSION/bin/linux/amd64/kubectl
    chmod +x $HOME/bin/kubectl
    echo "kubectl: Installing"
fi

if [ -f $HOME/bin/kops ]; then
    echo "kops: Installed"
else
    echo "kops: Installing"
    export KOPS_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L -o $HOME/bin/kops https://github.com/kubernetes/kops/releases/download/$KOPS_VERSION/kops-linux-amd64
    chmod +x $HOME/bin/kops
    echo "kops: Installed"
fi

TEMPDIR=/tmp

DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
KOPS_STATE_STORE="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)-kops"
PEM_FILE=$TEMPDIR/$DOMAIN_NAME_SAFE.pem
PUB_FILE=$TEMPDIR/$DOMAIN_NAME_SAFE.pub

aws s3 ls $DOMAIN_NAME_S3 >/dev/null 2>&1
if [ $? == 0 ]; then
    echo "s3 domain store: Exists"
else
    aws s3 mb $DOMAIN_NAME_S3 >/dev/null 2>&1
    echo "s3 domain store: Created"
fi

aws s3 ls $KOPS_STATE_STORE >/dev/null 2>&1
if [ $? == 0 ]; then
    echo "s3 kops state store: Exists"
else
    aws s3 mb $KOPS_STATE_STORE >/dev/null 2>&1
    echo "s3 kops state store: Created"
fi

echo "AWS_ACCESS_KEY_ID:     $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo "AWS_REGION:            $AWS_REGION"
echo "DOMAIN_NAME:           $DOMAIN_NAME"
echo "PEM_FILE:              $PEM_FILE"
echo "PUB_FILE:              $PUB_FILE"
echo "----------"
echo "DOMAIN_NAME_S3:        $DOMAIN_NAME_S3"
echo "KOPS_STATE_STORE:      $KOPS_STATE_STORE"
echo "kubectl version:       $(kubectl version --client)"
echo "kops version:          $(kops version)"

# If the S3 object does not exist, then create the key pair.
aws s3 ls $DOMAIN_NAME_S3/$DOMAIN_NAME_SAFE.pem >/dev/null 2>&1
if [ $? == 0 ]; then
    echo "kops key pair: Exists"
else
    echo "kops key pair: Creating"
    aws ec2 create-key-pair \
        --region $AWS_REGION \
        --query 'KeyMaterial' \
        --key-name $DOMAIN_NAME_SAFE \
        --output text > $PEM_FILE

    aws s3 cp $PEM_FILE $DOMAIN_NAME_S3
    echo "kops key pair: Created"
fi

# If the local file does not exist, pull it from S3.
if [ -f $PEM_FILE ]; then
    echo "local kops key pair: Exists"
else
    aws s3 cp $DOMAIN_NAME_S3/$DOMAIN_NAME_SAFE.pem $PEM_FILE
    echo "local kops key pair: Copied"
fi

# make sure the pki files have the right permissions.
chmod 600 $PEM_FILE $PUB_FILE

# Create a public key from the pem file.
if [ -f $PUB_FILE ]; then
    echo "local kops public key: Exists"
else
    ssh-keygen -y -f $PEM_FILE > $PUB_FILE
    echo "local kops public key: Created"
fi

COREOS_AMI=$(curl -s https://coreos.com/dist/aws/aws-stable.json | jq -r '.["us-east-1"].hvm')

echo "kubernetes cluster: Creating"

$HOME/bin/kops create cluster \
  --cloud=aws \
  --image $COREOS_AMI \
  --ssh-public-key $PUB_FILE \
  --yes \
  --zones=$AWS_ZONE \
  $DOMAIN_NAME

echo "--------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------"
echo "|| Run the following command so kubectl connects to the $DOMAIN_NAME cluster: ||"
echo "|| KOPS_STATE_STORE=$KOPS_STATE_STORE"
echo "--------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------"
echo "Continue to run 'kops validate cluster' until you see 'Your cluster $DOMAIN_NAME is ready'."
echo "----------"
