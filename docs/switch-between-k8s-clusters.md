# Switch Between K8S Clusters

Kubectl relies on two pieces of data in order to connect to a K8S cluster:

* A context.
* The KOPS_STATE_STORE environment variable.

When a cluster is created, you should have a context created as well. The following command lists the
contexts available to you. You'll see many more than you care about. You'll also see usernames and passwords that can connect to the API server.

```
kubectl config view
```

## Manual Process

When you know what context is needed, set your context like this:

```
kubectl config set-context va-oit.cloud
```

Now the KOPS_STATE_STORE environment variable needs to be set. Hopefully, you are using a naming convention or have the S3 bucket name stored from previous work.

I recommend using a naming convention based on the domain name associated with the cluster. This is the command sequence that I use.

```
DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
KOPS_STATE_STORE="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)-kops"
```

With these two steps complete, you should be connected to the cluster. Run the following command to validate the connection.

```
kops validate cluster
```

## Scripted Process

If you have created an `env` file for your cluster, then you can use a script to switch between clusters.

```
source source-me.cluster-connect.sh -f ~/va-oit.cloud.env
source source-me.cluster-connect.sh -f ~/va-oit-blue.cloud.env
```
