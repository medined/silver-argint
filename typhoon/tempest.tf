module "tempest" {
  source = "git::https://github.com/poseidon/typhoon//aws/fedora-coreos/kubernetes?ref=v1.18.0"

  # AWS
  cluster_name = "tempest"
  dns_zone     = "david.va-oit.cloud"
  dns_zone_id  = "Z05543821H7X7WYIBGOOC"

  # configuration
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCM1j8+LRV9elXX2gcrEWh5HdRfZH5HxzMiFxtAqCgia6A1GllacLrv/CUwj3jocugCagl3u9aDVKQIoqDZ1JtFQ+itcH+6zQqx8sVLOu7Si40PpHSGlXjqJaUaNkFW7yU7vcW4TsBp/J6pzsXq9bbt2tB4bQVrPo3VjrsPcvVVda7s2M+Cv2b0I9zuvrbvUgzOMOnQWKNsBPuNoX4R61dKS/tk73JYBIUlRqqEJcHxTkdwFyKVZ3mssJRYYC5UipSVDoW7A5B0nXvlJo3zO3rp2Dl/pbWsvhb39dOiRh2thscHJotVzV4IJ4QHkvQ5UPwQau/OWi3AJwKU5B3k+Jwt"

  # optional
  worker_count = 2
  worker_type  = "t3.small"
}
