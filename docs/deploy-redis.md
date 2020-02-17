# Deploy Redis

Redis is an open source (BSD licensed), in-memory data structure store, used as a database, cache and message broker.

## Installation

* Pay attention to the output because it will tell you the hostname and other connection information. Note that a random name is being generated and it is being deployed into the default namespace.

```
helm install stable/redis --generate-name
```

* See the service running.

```
kubectl get service
```

## Connection

After the `helm` command is complete, it will print connection information like the following. Make sure to save the information somewhere. Remember that every installation will have different connection information. The information below is just an example.

```
NAME: redis-1581909462
LAST DEPLOYED: Sun Feb 16 22:17:44 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **
Redis can be accessed via port 6379 on the following DNS names from within your cluster:

redis-1581909462-master.default.svc.cluster.local for read/write operations
redis-1581909462-slave.default.svc.cluster.local for read-only operations


To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace default redis-1581909462 -o jsonpath="{.data.redis-password}" | base64 --decode)

To connect to your Redis server:

1. Run a Redis pod that you can use as a client:

   kubectl run --namespace default redis-1581909462-client --rm --tty -i --restart='Never' \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
   --image docker.io/bitnami/redis:5.0.7-debian-10-r0 -- bash

2. Connect using the Redis CLI:
   redis-cli -h redis-1581909462-master -a $REDIS_PASSWORD
   redis-cli -h redis-1581909462-slave -a $REDIS_PASSWORD

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/redis-1581909462-master 6379:6379 &
    redis-cli -h 127.0.0.1 -p 6379 -a $REDIS_PASSWORD
```
