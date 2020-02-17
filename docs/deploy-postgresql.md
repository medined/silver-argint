# Deploy PostgreSQL

PostgreSQL is the world's most advanced open source relational database. 

## Installation

* Pay attention to the output because it will tell you the hostname and other connection information. Note that a random name is being generated and it is being deployed into the default namespace.

```
helm install stable/postgresql --generate-name
```

* See the service running.

```
kubectl get service
```

## Connection

After the `helm` command is complete, it will print connection information like the following. Make sure to save the information somewhere. Remember that every installation will have different connection information. The information below is just an example.

```
NAME: postgresql-1581909201
LAST DEPLOYED: Sun Feb 16 22:13:23 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS name from within your cluster:

    postgresql-1581909201.default.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgresql-1581909201 -o jsonpath="{.data.postgresql-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run postgresql-1581909201-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.7.0-debian-10-r0 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgresql-1581909201 -U postgres -d postgres -p 5432

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/postgresql-1581909201 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
```
