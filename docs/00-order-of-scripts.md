# Order of Scripts

This project has a lot of scripts. The code block below shows one possible order to run them.


```
cat <<EOF > $HOME/va-oit.cloud.env
ACME_REGISTRATION_EMAIL=dmedined@crimsongovernment.com
AWS_ACCESS_KEY_ID=<access key>
AWS_SECRET_ACCESS_KEY=<secret access key>
AWS_REGION=us-east-1
AWS_ZONES=us-east-1a
DOMAIN_NAME=va-oit.cloud
MASTER_ZONES=us-east-1a
NODE_COUNT=2
EOF

CONFIG_FILE="$HOME/david.va-oit.cloud.env"
NAMESPACE=sandbox
JENKINS_ADMIN_PASSWORD=$(cat ~/password-jenkins.txt)
source ./cluster-create.sh -f $CONFIG_FILE
./dashboard-proxy-start.sh
./helm-install.sh
./krew-install.sh
./namespace-create.sh $NAMESPACE
./cert-manager-install.sh -f $CONFIG_FILE $NAMESPACE

./istio-install.sh -f $CONFIG_FILE $NAMESPACE

./create-vanity-url.sh -f $CONFIG_FILE $NAMESPACE registry
./custom-docker-registry-install.sh -f $CONFIG_FILE $NAMESPACE

./create-vanity-url.sh -f $CONFIG_FILE $NAMESPACE jenkins
./jenkins-helm-set-admin-password-secret.sh $NAMESPACE $JENKINS_ADMIN_PASSWORD
./jenkins-helm-install.sh -f $CONFIG_FILE $NAMESPACE
./jenkins-helm-check.sh $NAMESPACE
./jenkins-proxy-start.sh $NAMESPACE
```

## Future

Some scripts have not been completed. Do not run them.

### Harbor Installation

The install process seems easy until you need to setup the values yaml file. Then complexity goes way up.

```
./create-vanity-url.sh -f $CONFIG_FILE $NAMESPACE harbor
./TDB-COMPLEX-harbor-install.sh

```