
locals {
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCM1j8+LRV9elXX2gcrEWh5HdRfZH5HxzMiFxtAqCgia6A1GllacLrv/CUwj3jocugCagl3u9aDVKQIoqDZ1JtFQ+itcH+6zQqx8sVLOu7Si40PpHSGlXjqJaUaNkFW7yU7vcW4TsBp/J6pzsXq9bbt2tB4bQVrPo3VjrsPcvVVda7s2M+Cv2b0I9zuvrbvUgzOMOnQWKNsBPuNoX4R61dKS/tk73JYBIUlRqqEJcHxTkdwFyKVZ3mssJRYYC5UipSVDoW7A5B0nXvlJo3zO3rp2Dl/pbWsvhb39dOiRh2thscHJotVzV4IJ4QHkvQ5UPwQau/OWi3AJwKU5B3k+Jwt"
}

output "ssh_authorized_key" {
  value = "${local.ssh_authorized_key}"
}

module "tempest" {
  #source = "git::https://github.com/poseidon/typhoon//aws/fedora-coreos/kubernetes?ref=v1.18.0"
  source = "../../../typhoon/aws/fedora-coreos/kubernetes"

  # AWS
  cluster_name = "tempest"
  dns_zone     = "david.va-oit.cloud"
  dns_zone_id  = "Z05543821H7X7WYIBGOOC"
#  vpc_id       = "vpc-04bdc9b68b19472c3"

  ssh_authorized_key = "${local.ssh_authorized_key}"

  # optional
  worker_count = 2
  worker_type  = "t3.small"
}

# module "tempest-worker-pool" {
#   source = "git::https://github.com/poseidon/typhoon//aws/fedora-coreos/kubernetes/workers?ref=v1.18.0"

#   # AWS
#   vpc_id          = module.tempest.vpc_id
#   subnet_ids      = module.tempest.subnet_ids
#   security_groups = module.tempest.worker_security_groups

#   # configuration
#   name               = "tempest-pool"
#   kubeconfig         = module.tempest.kubeconfig
#   ssh_authorized_key = "${local.ssh_authorized_key}"

#   # optional
#   worker_count  = 2
#   instance_type = "t3.small"
#   os_image      = "coreos-beta"
#   spot_price    = 0.01
#   node_labels   = ["worker-pool=spot"]
# }

# Obtain cluster kubeconfig
resource "local_file" "kubeconfig-tempest" {
  content  = module.tempest.kubeconfig-admin
  filename = "/home/medined/.kube/configs/tempest-config"
}

resource "local_file" "ingress_dns_name" {
  content  = module.tempest.ingress_dns_name
  filename = "tempest.ingress_dns_name.txt"
}
