# Introduction to Distroless Containers

## Description

"Distroless" images contain only your application and its runtime dependencies. They do not contain package managers, shells or any other programs you would expect to find in a standard Linux distribution.

Beyond providing significantly less "attack surface" for hackers, they are much smaller than a normal image.

The node:10.17.0 image is 903MB. While the equivalent gcr.io/distroless/nodejs image is 81.2MB. The distroless image is over 90% smaller!

The steps below show how to use a distroless image to run a "Hello World" job inside Kubernetes.

## Links

* https://github.com/GoogleContainerTools/distroless


## Example Using Kubernetes Job

* Create a directory to hold docker files and connect into it.

```
mkdir docker
pushd docker
```

* Create hello.js

```
cat <<EOF > hello.js
console.log("Hello World");
EOF
```

* Create a Dockerfile.

```
cat <<EOF > Dockerfile
FROM node:10.17.0 AS build-env
ADD . /app
WORKDIR /app

FROM gcr.io/distroless/nodejs
COPY --from=build-env /app /app
WORKDIR /app
CMD ["hello.js"]
EOF
```

* Set the namespace.

```
NAMESPACE=sandbox
```

* Set domain name.

```
DOMAIN_NAME="va-oit-green.cloud"
REGISTRY_HOST="registry.$DOMAIN_NAME"
```

* Set the image name and version.

```
IMAGE_NAME=ic1-hello-world
IMAGE_VERSION=0.0.1
IMAGE_INFO="$IMAGE_NAME"
```

* Build the image.

```
docker build -t $IMAGE_INFO .
```

* Run the image.

```
docker run -it --rm $IMAGE_INFO
```

* Push the image into the k8s docker registry.

```
../custom-docker-registry-login.sh
docker tag $IMAGE_INFO $REGISTRY_HOST/$IMAGE_INFO
docker push $REGISTRY_HOST/$IMAGE_INFO
```

* Run the image as a job in k8s.

```
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $IMAGE_NAME
spec:
  template:
    spec:
      containers:
      - name: $IMAGE_NAME
        image: $REGISTRY_HOST/$IMAGE_INFO
        imagePullPolicy: Always
      imagePullSecrets:
      - name: docker-registry-credentials
      restartPolicy: Never
  backoffLimit: 4
EOF
```

* Get the pod name.

```
kubectl get pods --selector "job-name=$IMAGE_NAME"
```

* Get the pod log, which is also the job log.

```
kubectl logs <pod-name>
Hello World
```

* Pop out of the docker directory.

```
popd
```
