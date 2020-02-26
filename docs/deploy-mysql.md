# Deploy MySQL

MySQL is the world's most popular open source database. 

## Installation

* Install MySQL. Pay attention to the output because it will tell you the hostname and other connection information. Note that a random name is being generated and it is being deployed into the default namespace.

```
helm install stable/mysql --generate-name
```

* See the service running.

```
kubectl get service
```

## Connection

After the `helm` command is complete, it will print connection information like the following. Make sure to save the information somewhere. Remember that every installation will have different connection information. The information below is just an example.

```
MySQL can be accessed via port 3306 on the following DNS name from within your cluster:
mysql-1581810862.default.svc.cluster.local

To get your root password run:

MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default mysql-1581810862 -o jsonpath="{.data.mysql-root-password}" | base64 --decode; echo)

To connect to your database:

1. Run an Ubuntu pod that you can use as a client:

    kubectl run -i --tty ubuntu --image=ubuntu:16.04 --restart=Never -- bash -il

2. Install the mysql client:

    $ apt-get update && apt-get install mysql-client -y

3. Connect using the mysql cli, then provide your password:

    mysql -h mysql-1581810862 -p

To connect to your database directly from outside the K8s cluster:
    MYSQL_HOST=127.0.0.1
    MYSQL_PORT=3306

    # Execute the following command to route the connection:
    kubectl port-forward svc/mysql-1581810862 3306

    mysql -h ${MYSQL_HOST} -P${MYSQL_PORT} -u root -p${MYSQL_ROOT_PASSWORD}
```