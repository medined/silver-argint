# Highly Available Kubernetes Cluster

This article shows how to create a multi-master, multi-node cluster.

## Links

* https://github.com/kubernetes/kops/blob/master/docs/examples/coreos-kops-tests-multimaster.md

If you want to know how manually create a cluster see (create-custer.md). This article shows how to use the `cluster-create.sh` script.

### Steps

* Update AWS configuration file, ~/.aws/credentials. Set AWS_PROFILE in ~/.bashrc

* Register a domain using Route53. For example, using va-oit.cloud. Wait until the domain has been provisioned and you can find it using a command like the following.

```
dig NS va-oit.cloud
```

* Create a parameters file which configures the script. It should look like the following. Put the script in your home directory or somewhere else outside of this project's directory.

```
cat <<EOF > ~/va-oit-blue.cloud.ha.env
AWS_ACCESS_KEY_ID=AKIAXLYWH3DH2FXXXXXX
AWS_SECRET_ACCESS_KEY=HL0dvxqDOX4RXJN7BQRZI/HD02WDW2SwV5XXXXXX
AWS_REGION=us-east-1
AWS_ZONES=us-east-1a,us-east-1b,us-east-1c
DOMAIN_NAME=va-oit-blue.cloud
MASTER_ZONES=us-east-1a,us-east-1b,us-east-1c
NODE_COUNT=2
EOF
```

If you want a cluster with one master, only specify one zone in both AWS_ZONES and MASTER_ZONES.

* Create the cluster.

```
source cluster-create.sh -f ~/va-oit-blue.cloud.ha.env
```

* As a side note, you can delete the cluster you just created using the following command.

```
./cluster-delete.sh -f ~/va-oit-blue.cloud.ha.env
```
