#!/usr/bin/env bash

# Set net.bridge.bridge-nf-call-iptables to 1 so that 
# Linux Node’s iptables can correctly see bridged 
# traffic.

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

echo "Install CNI plugins (required for most pod network)"
CNI_VERSION="v0.8.2"
mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz

echo "Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI))"
CRICTL_VERSION="v1.17.0"
mkdir -p /opt/bin
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C /opt/bin -xz

echo "Install kubeadm, kubelet, kubectl and add a kubelet systemd service"

if [ ! -f /opt/bin/kubeadm ]; then
    RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
    mkdir -p /opt/bin
    cd /opt/bin
    curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
    chmod +x {kubeadm,kubelet,kubectl}
fi

RELEASE_VERSION="v0.2.7"
if [ ! -f /etc/systemd/system/kubelet.service ]; then
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:/opt/bin:g" > /etc/systemd/system/kubelet.service
fi

if [ ! -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ]; then
    mkdir -p /etc/systemd/system/kubelet.service.d
    curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:/opt/bin:g" > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

# Enable and start kubelet
systemctl enable --now kubelet

# pull docker images used by kubeadm
export PATH=$PATH:/opt/bin:/opt/cni/bin
kubeadm config images pull

#####
# SELinux Rules

cat <<EOF > audit-rules.te
module audit-rules 1.0;
require {
  type cert_t;
  type container_file_t;
  type container_runtime_t;
  type container_t;
  type http_port_t;
  type init_t;
  type init_var_run_t;
  type kernel_t;
  type kmsg_device_t;
  type unreserved_port_t;
  type var_t;
  type var_run_t;

  class chr_file { read };
  class file { execute execute_no_trans map open read write };
  class service { start };
  class sock_file { create rename unlink };
  class system { syslog_read };
  class tcp_socket { name_connect };
  class unix_stream_socket { connectto };
}
#============= container_t ==============
allow container_t cert_t:file { open read };
#============= init_t ==============
allow init_t container_file_t:sock_file { create unlink };
allow init_t container_runtime_t:file write;
allow init_t container_runtime_t:unix_stream_socket connectto;
allow init_t http_port_t:tcp_socket name_connect;
allow init_t init_var_run_t:service start;
allow init_t kernel_t:system syslog_read;
allow init_t kmsg_device_t:chr_file read;
allow init_t unreserved_port_t:tcp_socket name_connect;
allow init_t var_run_t:sock_file rename;
allow init_t var_t:file { execute execute_no_trans map open read };
EOF

checkmodule -M -m -o audit-rules.mod audit-rules.te
semodule_package -o audit-rules.pp -m audit-rules.mod
semodule -i audit-rules.pp
