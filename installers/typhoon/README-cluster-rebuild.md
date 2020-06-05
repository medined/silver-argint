# Rebuilding Cluster

* Run `terraform destroy`

* Wait 10 minutes to make sure AWS resources are gone.

* Check https://github.com/poseidon/typhoon to see if version has changed.

* Run `terraform init`

* Run `terraform apply`

* Execute the steps in the docs directory.

* Update Route53 sub-domains to point to the new load balancer.

