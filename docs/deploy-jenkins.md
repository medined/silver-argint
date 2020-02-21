# Research

* pre-emptible to reduce cost.
 
# Deploy Jenkins

Jenkins is an open-source automation server that lets you flexibly orchestrate your build, test, and deployment pipelines.

## Steps

### Create Custom jnlp-slave Image

When a pipeline job is executed by Jenkins, it starts a container based on the `jenkins/jnlp-slave` image. You can build your own custom docker image with whatever build tools are needed. Since the range of build tools is quite large, we'll just show the steps to build a custom image. You'll need to adjust the `Dockerfile` to match your particular needs.

```
cat <<EOF > Dockerfile
FROM jenkins/jnlp-slave:3.27-1
EOF

DOCKER_HUB_USER=medined
docker build -t $DOCKER_HUB_USER/jnlp-slave:0.0.1 .
docker login
docker push $DOCKER_HUB_USER/jnlp-slave:0.0.1
```

Of course, you should test your image before pushing it. Below is one possible command to do this. The `Dockerfile` is ignored in this project. Therefore, you should create a sub-directory if you want a permanent record of your custom jnlp-slave.

```
docker run -it --rm $DOCKER_HUB_USER/jnlp-slave:0.0.1 /bin/bash
```

In the `values.jenkins.yaml` file created below to configure the jenkins deployment, this custom image will be used. You should adjust to fix your situation.

### Start Pod

* Pull all values from the jenkins helm chart.

```
helm inspect values stable/jenkins > yaml/values.jenkins.original.yaml
```

* The shortcut to starting the pod is to run the following. Otherwise, run the steps below. Note that the script and the steps might be out of sync. This script will create the values yaml file, run the helm chart, and start the proxy.

```
./run-jenkins.sh
# wait until the pod is ready.
./run-jenkins-proxy.sh
```

* Create a values file to customize parameters of the jenkins installation.

```
cat <<EOF > yaml/values.jenkins.yaml
master:
  runAsUser: 1000
  fsGroup: 1000
  installPlugins:
    - nodejs:1.3.4
agent:
  enabled: true
  image: "medined/jnlp-slave"
  tag: "0.0.1"
  alwaysPullImage: true
EOF
```

* Deploy Jenkins. This will create a persistent volume of 8GB and one master node.

```
helm install jenkins stable/jenkins -f yaml/values.jenkins.yaml --namespace sandbox
```

  * Delete jenkins.

```
./kill-jenkins.sh
```

### Verify Deployment

Since you are using a customized set of values, you might run into pod startup issues. Firstly, view the pods to see if the jenkins pod is running.

```
$ kubectl get pods | grep jenkins
jenkins-cff4d4c5f-m7hw6                              0/1     Init:CrashLoopBackOff   9          26m
```

### Debug Deployment

* Start the dashboard proxy.

```
./run-dashboard-proxy.sh
```

* Visit the pods in the `sandbox` namespace.

```
firefox http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/pod?namespace=sandbox
```

* Click on the jenkins pod.

* Click on the logs icon in the top right. It looks like a paragraph of text.

* You'll see one set of logs.

* On the top left, you'll see "Logs From". Near that location is a drop-down button which might show a selection of containers. For example, there might be Init Containers.

* Good luck.

### Post Deployment

* Visit Manage Jenkins > Global Tool Configuration.
* Click 'Add NodeJS'.
* Use 'nodejs' as name. Leave everything else as default.
* Click 'Save'

### Start Proxy

* Start a local proxy to the Jenkins service in the background. This script will print the `admin` password and start the proxy service. When you are done with the proxy, run `kill-jenkins-proxy.sh`. You can run `view-jenkins-password.sh` whenever you need to know the jenkins password.

```
./run-jenkins-proxy.sh
```

* Visit http://127.0.0.1:8080. Login as `admin` using the password from the previous step. Note that you'll see a "It appears that your reverse proxy set up is broken." message on the Manage Jenkins page. This message can be ignored because, I think, you are using a local proxy.
