# Deploy Jenkins

Jenkins is an open-source automation server that lets you flexibly orchestrate your build, test, and deployment pipelines.

## Links

* https://cloud.google.com/solutions/jenkins-on-container-engine

## Research

* pre-emptible to reduce cost.
 
## Steps

* Create a values file to customize parameters of the jenkins installation.

```
cat <<EOF > yaml/values.yaml
master:
  InstallPlugins:
    - kubernetes
    - workflow-aggregator
    - workflow-job
    - credentials-binding
    - git
    - github
    - github-api
    - github-branch-source
EOF
```

* Deploy Jenkins. This will create a persistent volume of 8GB and one master node.

```
helm install jenkins stable/jenkins -f yaml/values.yaml --namespace sandbox
```

  * Delete jenkins.

```
helm uninstall jenkins --namespace sandbox
```

* Start a local proxy to the Jenkins service.

```
export POD_NAME=$(kubectl get pods \
  --namespace sandbox \
  -l "app.kubernetes.io/component=jenkins-master" \
  -l "app.kubernetes.io/instance=jenkins" \
  -o jsonpath="{.items[0].metadata.name}"
)
kubectl --namespace sandbox port-forward $POD_NAME 8080:8080
```

* Get the `admin` user password. You'll paste this into the Jenkins login page.

```
printf $(kubectl get secret --namespace default jenkins-1581802921 -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

* Visit http://127.0.0.1:8080. Login as `admin` using the password from the previous step. Note that you'll see a "It appears that your reverse proxy set up is broken." message on the Manage Jenkins page. This message can be ignored because, I think, you are using a local proxy.

* Visit http://127.0.0.1:8080/pluginManager/ to update plugins as needed.


## Create vanity url.

NOTE: This is not working.

* Create a vanity URL for the echo service.

  * Define the DNS action which is inserting or updating the echo hostname.

```
cat <<EOF > json/dns-action.json
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "jenkins.$NAME",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$K8S_HOSTNAME"
          }
        ]
      }
    }
  ]
}
EOF

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name==\`$NAME.\`].Id" --output text)

echo "NAME:           $NAME"
echo "HOSTED_ZONE_ID: $HOSTED_ZONE_ID"

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://json/dns-action.json
```

* Check the DNS record was created.

```
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query="ResourceRecordSets[?Name==\`jenkins.$NAME.\`]"
``

* Visit jenkins.

```
firefox https://jenkins.va-oit.cloud/login
```
