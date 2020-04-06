# Research

* pre-emptible to reduce cost.
 
# Deploy Jenkins

Jenkins is an open-source automation server that lets you flexibly orchestrate your build, test, and deployment pipelines.

## Steps

### Create Custom jnlp-slave Image

When a pipeline job is executed by Jenkins, it starts a container based on the `jenkins/jnlp-slave` image. You can build your own custom docker image with whatever build tools are needed. Since the range of build tools is quite large, we'll just show the steps to build a custom image. You'll need to adjust the `Dockerfile` to match your particular needs. A more advanced Docker file is in the `jnlp-slave` directory.

```
cat <<EOF > Dockerfile
FROM jenkins/jnlp-slave:3.27-1
USER root
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -
RUN apt-get install -y nodejs
USER jenkins
EOF

DOCKER_HUB_USER=medined
docker build -t $DOCKER_HUB_USER/jnlp-slave-nodejs:13 .
docker login
docker push $DOCKER_HUB_USER/jnlp-slave-nodejs:13
```

Of course, you should test your image before pushing it. Below is one possible command to do this. The `Dockerfile` is ignored in this project. Therefore, you should create a sub-directory if you want a permanent record of your custom jnlp-slave.

```
docker run -it --rm $DOCKER_HUB_USER/jnlp-slave-nodejs:13 /bin/bash
```

In the `values.jenkins.yaml` file created below to configure the jenkins deployment, this custom image will be used. You should adjust to fix your situation.

### Start Jenkins Using Scripts

* Create `./password-jenkins.txt` which holds an admin password. Below is one way to create such a file. However, the password can be whatever you want. Using a UUID is not the most convenient technique.

```
uuid > password-jenkins.txt
```

* Run the scripts below.

```
./jenkins-helm-install.sh
./jenkins-helm-check.sh
# wait until the pod is ready.
./jenkins-proxy-start.sh
```

### Start Jenkins Using CLI

* Pull all values from the jenkins helm chart.

```
helm inspect values stable/jenkins > yaml/values.jenkins.original.yaml
```

* Create a values file to customize parameters of the jenkins installation.

```
cat <<EOF > yaml/values.jenkins.yaml
master:
  runAsUser: 1000
  fsGroup: 1000
agent:
  enabled: true
  image: "medined/jnlp-slave-nodejs"
  tag: "13"
  alwaysPullImage: true
EOF
```

* Deploy Jenkins. This will create a persistent volume of 8GB and one master node.

```
helm install jenkins stable/jenkins -f yaml/values.jenkins.yaml --namespace sandbox
```

  * Delete jenkins. When you want to try a different Jenkins configuration, starting over is easy. After running the scripts, wait a few seconds.

```
./jenkins-helm-uninstall.sh
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
./dashboard-proxy-start.sh
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

### Start Proxy

* Start a local proxy to the Jenkins service in the background. This script will print the `admin` password and start the proxy service. When you are done with the proxy, run `kill-jenkins-proxy.sh`. The Jenkins password should be in the `password-jenkins.txt` file.

```
./run-jenkins-proxy.sh
```

* Visit http://127.0.0.1:8080. Login as `admin` using the password from the previous step. Note that you'll see a "It appears that your reverse proxy set up is broken." message on the Manage Jenkins page. This message can be ignored because, I think, you are using a local proxy.

### Post Deployment

placeholder.

### Test NodeJS Plugin

This pipeline build will use the custom jnlp-slave image that contains nodejs.

* Click 'New Item'.
* Enter name of 'nodejs-first-build'.
* Click Pipeline project.
* Click Ok.
* Add the following as the Pipeline script.
```
pipeline {
  agent any
 
  stages {
    stage('Example') {
      steps {
        sh 'node --version'
      }
    }
  }
}
```
* Click Save.
* Click Build Now.
* Click on the new build number.
* Click on Console Output. You should see the build as it progresses. Hopefully, nodejs will be downloaded, unpacked and the build will be successful.
