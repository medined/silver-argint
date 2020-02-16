# Deploy Jenkins

## Links

* https://cloud.google.com/solutions/jenkins-on-container-engine
 
## Steps

* Specify Docker Hub user account.

```
export DH_USER=medined
```

* Start Jenkins. This will crate a persistent volume of 8GB and one master node.

```
helm install stable/jenkins --generate-name
```

* Start a local proxy to the Jenkins service.

```
export POD_NAME=$(kubectl get pods \
  --namespace default \
  -l "app.kubernetes.io/component=jenkins-master" \
  -l "app.kubernetes.io/instance=jenkins-1581802921" \
  -o jsonpath="{.items[0].metadata.name}")

kubectl --namespace default port-forward $POD_NAME 8080:8080
```

* Get the `admin` user password. You'll paste this into the Jenkins login page.

```
printf $(kubectl get secret --namespace default jenkins-1581802921 -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

* Visit http://127.0.0.1:8080. Login as `admin` using the password from the previous step.

* Visit http://127.0.0.1:8080/pluginManager/ to update plugins as needed.

