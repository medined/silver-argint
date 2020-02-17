# Deploy Mongo

MongoDB is a general purpose, document-based, distributed database built for modern application developers and for the cloud era.

## Installation

* Pay attention to the output because it will tell you the hostname and other connection information. Note that a random name is being generated and it is being deployed into the default namespace.

```
helm install stable/mongodb --generate-name
```

* See the service running.

```
kubectl get service
```

## Connection

After the `helm` command is complete, it will print connection information like the following. Make sure to save the information somewhere. Remember that every installation will have different connection information. The information below is just an example.

```
NAME: mongodb-1581909692
LAST DEPLOYED: Sun Feb 16 22:21:33 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

MongoDB can be accessed via port 27017 on the following DNS name from within your cluster:

    mongodb-1581909692.default.svc.cluster.local

To get the root password run:

    export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace default mongodb-1581909692 -o jsonpath="{.data.mongodb-root-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run --namespace default mongodb-1581909692-client --rm --tty -i --restart='Never' --image bitnami/mongodb --command -- mongo admin --host mongodb-1581909692 --authenticationDatabase admin -u root -p $MONGODB_ROOT_PASSWORD

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/mongodb-1581909692 27017:27017 &
    mongo --host 127.0.0.1 --authenticationDatabase admin -p $MONGODB_ROOT_PASSWORD
```
