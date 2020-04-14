# Configure Jenkins With Cluster Credentials

Anything that works with a Kuberneters cluster has to authenticate and have the appropriate authorizations. Service accounts perform this function. You'll create a service account and find its token. That token will be added to Jenkins and referenced in pipelines.

## Create the Credential (i.e. the token)

If you installed Jenkins using the `jenkins-helm-install.sh` then the service account and cluster role binding have already been created.

* Create a service account and get the token associated with it.

```
NAMESPACE=sandbox

kubectl create serviceaccount jenkins-deployer --namespace $NAMESPACE

kubectl create clusterrolebinding jenkins-deployer-role \
  --clusterrole=cluster-admin \
  --serviceaccount=sandbox:jenkins-deployer

TOKEN_NAME=$(kubectl get serviceaccount jenkins-deployer --namespace $NAMESPACE -o go-template --template='{{range .secrets}}{{.name}}{{"\n"}}{{end}}')

TOKEN=$(kubectl get secrets $TOKEN_NAME --namespace $NAMESPACE -o go-template --template '{{index .data "token"}}' | base64 -d)
echo "TOKEN: $TOKEN"
```

* Here is another way to find the token.

```
SECRET_NAME=$(kubectl get secrets --namespace $NAMESPACE | grep jenkins-deployer-token | awk '{print $1}')
TOKEN=$(kubectl describe secret $SECRET_NAME --namespace $NAMESPACE | grep ^token | awk '{print $2}')
echo "TOKEN: $TOKEN"
```

## Add Credential to Jenkins

* Use the following script to start a local proxy for the Jenkins service.

```
./jenkins-proxy-start.sh $NAMESPACE
```

* Visit Jenkins. Login as the `admin` user. If you don't know the password, check `yaml/values.jenkins.yaml`.

```
firefox http://localhost:8080
```

* In Jenkins, create a credential which can be used to connect to a kubernetes cluster. The ID below is the credentials needed in the pipeline.
    * Click Credentials.
    * Click System.
    * Clck Add domain.
        * Domain Name: silver-argint
        * Click Ok.
    * Click Add credentials.
        * Kind: Secret text
        * Scope: Global
        * Secret: paste the token from above.
        * ID: jenkins-deployer-credentials
        * Description: used in jenkins pipelines to confgure kubectl
        * Click Ok.

### Creating a Jenkins Job With Pipeline Script

* Go to Jenkins home page.
* Click New Item.
    * Name: training-jenkins-kubernetes
    * Job Type: Pipeline
    * Click Ok.
* Configure the job.
    * In the Pipeline section, select Pipeline script.
    * Use the following as the script.
```
node {
  stage('List Pods') {
    withKubeConfig(credentialsId: 'jenkins-deployer-credentials', serverUrl: 'https://api.va-oit.cloud') {
        sh '''
            kubectl get pods
        '''
    }
  }
}
```

* Click Save.

* Click Build Now.

### Creating a Jenkins Job With Pipeline From GitHub project.

* Go to Jenkins home page.
* Click New Item.
    * Name: node-echo-server
    * Job Type: Pipeline
    * Click Ok.
* Configure the job.
    * Click Github Project, enter the project's url: https://github.com/medined/node-echo-server.git
    * In the Pipeline section, select Pipeline script from SCM.
    * Select Git as the SCM
    * Enter your project's GitHub URL as the Repository URL.
    * Click Save.
* Click Build Now.
