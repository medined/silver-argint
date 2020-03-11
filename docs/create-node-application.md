# Deploy a Node Application To Kubernetes Cluster

## Links

* https://www.tutorialspoint.com/nodejs/nodejs_first_application.htm

## Run Locally

### Install Simple NodeJS Web Server

* Install nvm, the node version manager

```
sudo apt-get update -y
sudo apt-get install -y build-essential checkinstall libssl-dev
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash
export NVM_DIR="/home/medined/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
nvm install stable
```

* Create Project.

```
cd /data/projects
git clone https://github.com/medined/simple-nodejs.git
cd simple-nodejs
```

* Install the project.

```
npm install
```

* Start the application.

```
node main.js
```

* Stop the application using ^c.

## Run Locally As Containers

* Install Docker. Go ahead. Come back when you are done.

* Build an image of the application.

```
docker build -t simple-nodejs:0.0.1 .
```

* Run the image.

```
docker run --name simple-nodejs -p 9999:9999 -d simple-nodejs:0.0.1
```

* Check the web server is running.

```
curl http://localhost:9999; echo
```

* Stop and remove the container.

```
docker stop simple-nodejs
docker rm simple-nodejs
```

### Push Image To Docker Registry

* Create a ID at https://hub.docker.com/signup.

* Log into the Docker Hub.

```
docker login
```

* Tag the image with your Docker Id. Mine is 'medined'. Then push it.

```
docker tag simple-nodejs:0.0.1 medined/simple-nodejs:0.0.1
docker push medined/simple-nodejs:0.0.1
```

* Rerun the application using the image at Docker Hub.

```
docker run --name simple-nodejs -p 9999:9999 -d medined/simple-nodejs:0.0.1
```

* Check the web server is running.

```
curl http://localhost:9999; echo
```

* Stop and remove the container.

```
docker stop simple-nodejs
docker rm simple-nodejs
```

### Run Web Server As Pod

This section will run the nodejs server in a single pod in the cluster. It won't be scalable but it will respond to HTTP requests.

* Create a pod to run the image. Note the following:
  * The port matches the exposed port in the Dockerfile.
  * The image matches the image pushed to the Docker registry.
  * The label will be used as a selector so it should be specific.

```
cat <<EOF > yaml/simple-nodejs-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-nodejs-pod
  labels:
    app: simple-nodejs
spec:
  containers:
  - name: simple-nodejs
    image: medined/simple-nodejs:0.0.1
    ports:
    - containerPort: 9999
EOF
kubectl apply -f yaml/simple-nodejs-pod.yaml
```

* Expose the application using a load balancer. Note that port 80 is exposed on the internet and forwarded to the internal target port. The selector points to the pod created above.

```
cat <<EOF > yaml/simple-nodejs-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: simple-nodejs-service
spec:
  type: LoadBalancer
  selector:
    app: simple-nodejs
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9999
EOF
kubectl apply -f yaml/simple-nodejs-service.yaml
```

* Find the load balancer endpoint.

```
kubectl get services simple-nodejs-service
```

* Use `dig` to wait for the load balancer to become available. When you see two IP addresses in the ANSWER section, it's good to receive requests.

* Use `curl` to test the application is running.

```
curl http://a268f64da0dfd4026910ab2f14379e61-1001451684.us-east-1.elb.amazonaws.com; echo
Hello World
```

* Delete the service and pod.

```
kubectl delete -f yaml/simple-nodejs-pod.yaml
kubectl delete -f yaml/simple-nodejs-service.yaml
```

### Run Web Server As Depoyment

In the manifest below, the selector field defines how the deployment finds which pods to manage. In this case, the match matches the label also defined in the manifest.

```
cat <<EOF > yaml/simple-nodejs-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-nodejs-deployment
  labels:
    app: simple-nodejs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: simple-nodejs
  template:
    metadata:
      labels:
        app: simple-nodejs
    spec:
      containers:
        - name: simple-nodejs
          image: medined/simple-nodejs:0.0.1
          imagePullPolicy: Always
          ports:
          - containerPort: 9999
---
apiVersion: v1
kind: Service
metadata:
  name: simple-nodejs-service
spec:
  type: LoadBalancer
  selector:
    app: simple-nodejs
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9999
EOF
kubectl apply -f yaml/simple-nodejs-deployment.yaml
```

* Use `dig` to wait for DNS to propagate and `curl` to test that the application is responding.
