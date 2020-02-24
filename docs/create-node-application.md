# Deploy a Node Application To Kubernetes Cluster

## Links

* https://learnk8s.io/nodejs-kubernetes-guide

## Run Locally

* Install nvm, the node version manager

```
sudo apt-get update -y
sudo apt-get install -y build-essential checkinstall libssl-dev
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash
export NVM_DIR="/home/medined/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
nvm install stable
```

* Install Mongo database. In this case, Mongo is not being enabled or started. It will not be started after a reboot. You'll start it later.

```
sudo apt-get install -y gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
sudo apt-get update -y
sudo apt-get install -y mongodb-org
```

* Clone project.

```
git clone https://github.com/learnk8s/knote-js
cd knote-js/01
```

* Install the project.

```
npm install
```

* Start the application.

```
sudo systemctl start mongod
node index.js
```

* Stop the application using ^c.

```
sudo systemctl stop mongod
```

* Stop mongo.

## Run Locally As Containers

* Install Docker. Go ahead. Come back when you are done.

* Switch to `knote-js/02`.

* Build an image of the application.

```
docker build -t knote .
```

* Create a Docker network.

```
docker network create knote
```

* Run mongo inside a container. This process will keep running.

```
docker run \
  --name=mongo \
  --rm \
  --network=knote mongo
```

* Run the node application inside another container.

```
docker run \
  --name=knote \
  --rm \
  --network=knote \
  -p 3000:3000 \
  -e MONGO_URL=mongodb://mongo:27017/dev \
  knote
```

* Stop both containers.

```
docker stop mongo knote
```

* Create a ID at https://hub.docker.com/signup.

* Log into the Docker Hub.

```
docker login
```

* Tag the image with your Docker Id. Mine is 'medined'. Then push it.

```
docker tag knote medined/knote-js:1.0.0
docker push medined/knote-js:1.0.0
```

* Rerun the application using the image at Docker Hub.

```
docker run \
  --name=mongo \
  --rm \
  --network=knote \
  mongo
docker run \
  --name=knote \
  --rm \
  --network=knote \
  -p 3000:3000 \
  -e MONGO_URL=mongodb://mongo:27017/dev \
  medined/knote-js:1.0.0
```

* Stop both containers.

```
docker stop mongo knote
```

## Run Inside Kubernetes

* Start a kubernetes cluster. 

* Switch to `knote-js/03`.

* Review kube/knote.yaml and kube/mongo.yaml.

* Deploy the application to the cluster.

```
kubectl apply -f kube
```

* View the application by visiting the Kubernetes Dashboard. Then clicking Services. Then clicking on the External Endpoint for the knote service.

* Scale the deployment.

```
kubectl scale --replicas=2 deployment/knote
```

* At this point, the application is storing images on the local file system. Therefore, if you upload an image and reload the page a few times it only be shown 50% of the time. Since information is stored locally on the server, this is a stateful application.

