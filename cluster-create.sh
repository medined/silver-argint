#!/bin/bash

#####
# This script spins-up a k8s cluster based on a configuration file.
# Here is an example configuration file.
#
#  ACME_REGISTRATION_EMAIL=dmedined@crimsongovernment.com
#  AWS_ACCESS_KEY_ID=XXXXAXLXXX3DH2FGKSXXX
#  AWS_SECRET_ACCESS_KEY=XXXdvxqDOX4RXJNXXXRZI/HD02WDW2SwV5Ck8XXX
#  AWS_REGION=us-east-1
#  AWS_ZONES=us-east-1a
#  DOMAIN_NAME=va-oit-blue.cloud
#  MASTER_ZONES=us-east-1a
#  NODE_COUNT=2

(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0
if [ "$SOURCED" == "0" ]; then
  echo "ERROR: Please source this script."
  exit
fi

if [ $# -ne 2 ]; then
  echo "Usage: -f [configuration file]"
  return
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    return
fi

# Since this script is being sourced, the relevant variables
# need to be unset. Otherwise, we might be using values from
# previous actions.

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_REGION
unset AWS_ZONES
unset DOMAIN_NAME
unset MASTER_ZONES
unset NODE_COUNT

CONFIG_FILE=$2
if [ ! -f $CONFIG_FILE ]; then
    echo "ERROR: Missing configuration file: $CONFIG_FILE"
    return
fi
source $CONFIG_FILE

if [ -z $AWS_ACCESS_KEY_ID ]; then
  echo "ERROR: Missing environment variable: AWS_ACCESS_KEY_ID"
  return
fi
if [ -z $AWS_SECRET_ACCESS_KEY ]; then
  echo "ERROR: Missing environment variable: AWS_SECRET_ACCESS_KEY"
  return
fi
if [ -z $AWS_REGION ]; then
  echo "ERROR: Missing environment variable: AWS_REGION"
  return
fi
if [ -z $AWS_ZONES ]; then
  echo "ERROR: Missing environment variable: AWS_ZONES"
  return
fi
if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  return
fi
if [ -z $MASTER_ZONES ]; then
  echo "ERROR: Missing environment variable: MASTER_ZONES"
  return
fi
if [ -z $NODE_COUNT ]; then
  echo "ERROR: Missing environment variable: NODE_COUNT"
  return
fi

# Does a bin directory exist in the user's home directory? This is where
# downloaded software will be placed.

[ -d $HOME/bin ] || mkdir $HOME/bin
grep "^export PATH=[$]PATH:[$]HOME/bin$" $HOME/.bashrc > /dev/null
if [ $? != 0 ]; then
    echo 'export PATH=$PATH:$HOME/bin' >> $HOME/.bashrc
fi

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

if [ -f $HOME/bin/jq ]; then
  echo "jq: installed"
else
  echo "jq: installing"
  curl -L -o $HOME/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  chmod +x $HOME/bin/jq
  echo "jq: Installed"
fi

TEMPDIR=/tmp

DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
KOPS_STATE_STORE="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)-kops"

KEY_PAIR_NAME="$DOMAIN_NAME_SAFE-k8s"
LOCAL_PEM_FILE="$TEMPDIR/$KEY_PAIR_NAME.pem"
LOCAL_PUB_FILE="$TEMPDIR/$KEY_PAIR_NAME.pub"

S3_PEM_FILE="$DOMAIN_NAME_S3/$KEY_PAIR_NAME.pem"

# Does the S3 bucket exist for random storage?
aws s3 ls $DOMAIN_NAME_S3 >/dev/null 2>&1
if [ $? == 0 ]; then
    echo "s3 domain store: Exists - $DOMAIN_NAME_S3"
else
    aws s3 mb $DOMAIN_NAME_S3 >/dev/null 2>&1 
    echo "s3 domain store: Created - $DOMAIN_NAME_S3"
fi

# Does the S3 bucket exist for kops storage?
aws s3 ls $KOPS_STATE_STORE >/dev/null 2>&1
if [ $? == 0 ]; then
    echo "s3 kops state store: Exists - $KOPS_STATE_STORE"
else
    aws s3 mb $KOPS_STATE_STORE >/dev/null 2>&1
    echo "s3 kops state store: Created - $KOPS_STATE_STORE"
fi

aws ec2 describe-key-pairs --region us-east-1 --key-names $KEY_PAIR_NAME 1>/dev/null 2>&1
if [ $? != 0 ]; then
    # The key needs to be created in AWS.
    echo "kops key pair: Creating - $KEY_PAIR_NAME - $LOCAL_PEM_FILE"
    aws ec2 create-key-pair \
        --region $AWS_REGION \
        --query 'KeyMaterial' \
        --key-name $KEY_PAIR_NAME \
        --output text > $LOCAL_PEM_FILE

    aws s3 cp $LOCAL_PEM_FILE $S3_PEM_FILE
    echo "kops key pair: Created"
else
    echo "kops key pair: Exists - $KEY_PAIR_NAME"
fi

# If the S3 object does not exist, bail.
aws s3 ls $S3_PEM_FILE >/dev/null 2>&1
if [ $? != 0 ]; then
    echo "FATAL: The S3 copy of the key pair PEM file is missing: $S3_PEM_FILE"
fi

# If the local file does not exist, pull it from S3.
if [ -f $LOCAL_PEM_FILE ]; then
    echo "local kops key pair: Exists - $LOCAL_PEM_FILE"
else
    aws s3 cp $S3_PEM_FILE $LOCAL_PEM_FILE
    echo "local kops key pair: Copied - $LOCAL_PEM_FILE"
fi

# make sure the pem file is read only.
chmod 600 $LOCAL_PEM_FILE

# Create a public key from the pem file.
if [ -f $LOCAL_PUB_FILE ]; then
    echo "local kops public key: Exists - $LOCAL_PUB_FILE"
else
    ssh-keygen -y -f $LOCAL_PEM_FILE > $LOCAL_PUB_FILE
    echo "local kops public key: Created - $LOCAL_PUB_FILE"
fi

# make sure the pki files have the right permissions.
chmod 600 $LOCAL_PEM_FILE $LOCAL_PUB_FILE

COREOS_AMI=$(curl -s https://coreos.com/dist/aws/aws-stable.json | $HOME/bin/jq -r '.["us-east-1"].hvm')

echo "kubernetes cluster: Creating"

DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
export KOPS_STATE_STORE="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)-kops"

$HOME/bin/kops create cluster \
  --cloud=aws \
  --image=$COREOS_AMI \
  --master-zones=$MASTER_ZONES \
  --name=$DOMAIN_NAME \
  --node-count=$NODE_COUNT \
  --ssh-public-key=$LOCAL_PUB_FILE \
  --zones=$AWS_ZONES \
  --yes

RED='\033[0;31m'
NC='\033[0m'

while [ "$(kubectl get nodes 2>/dev/null | grep -v STATUS | awk '{print $2}' | sort -u | wc -l)" != "1" ]
do
  NOW=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${RED}$NOW: Waiting 60 seconds for nodes to be ready. Expect errors below.${NC}"
  kops validate cluster
  kubectl get nodes
  sleep 60
done


kops validate cluster
kubectl get nodes
