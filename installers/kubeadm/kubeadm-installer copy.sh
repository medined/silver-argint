#!/usr/bin/env bash

K8S_REPO="kubernetes/kubernetes"
K8S_VERSION=${K8S_VERSION:-}

KUBEADM_RELEASE=${KUBEADM_RELEASE:-}

ARCH=${ARCH:-amd64}
ROOTFS=${ROOTFS:-/usr/local/bin}

get_git_latest_release() {
  curl --silent "https://api.github.com/repos/${1}/releases/latest" \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/'
}

# Handle no values for Versions
# --
# If no values are provided, get the latest release of k8s
if [[ -z "${K8S_VERSION}" ]]; then
  echo "[ENV] 'K8S_VERSION' is empty -> Getting latest release version"
  K8S_VERSION=$(get_git_latest_release $K8S_REPO)
fi
echo "[ENV] 'K8S_VERSION' = ${K8S_VERSION}"

# If no values are provided, use the same than k8s
if [[ -z "${KUBEADM_RELEASE}" ]]; then
  echo "[ENV] 'KUBEADM_RELEASE' is empty -> Getting same version as k8s"
  KUBEADM_RELEASE=${K8S_VERSION}
fi
echo "[ENV] 'KUBEADM_RELEASE' = ${KUBEADM_RELEASE}"

# Kubernetes Google Cloud Storage
# --
#
# Handling usage of Dev / Final release buckets
#
K8S_URL=${K8S_URL:-https://storage.googleapis.com/kubernetes-release/release}

echo "[Kubeadm] Selected version: ${KUBEADM_RELEASE}"
if [[ -z "${KUBEADM_URL}" ]]; then
  if [[ -n "${KUBEADM_VERSION/v[0-9].[0-9].[0-9]/}" ]]; then
    echo "[Kubeadm] KUBEADM_RELEASE ${KUBEADM_RELEASE} is a Pre-release version"
    KUBEADM_URL=https://storage.googleapis.com/kubernetes-release-dev/ci-cross
  else
    echo "[Kubeadm] KUBEADM_RELEASE ${KUBEADM_RELEASE} is a Release version"
    KUBEADM_URL=https://storage.googleapis.com/kubernetes-release/release
  fi
fi
echo "[Kubeadm] Download url: ${KUBEADM_URL}"

set -o errexit
set -o nounset

if [[ ! -f ${ROOTFS}/kubectl ]]; then
  curl -sSL ${K8S_URL}/${K8S_VERSION}/bin/linux/${ARCH}/kubectl > ${ROOTFS}/kubectl
  chmod +x ${ROOTFS}/kubectl
  echo "Installed kubectl."
else
  echo "Ignoring kubectl, since it seems to exist already"
fi

if [[ ! -f ${ROOTFS}/kubelet ]]; then
  curl -sSL ${K8S_URL}/${K8S_VERSION}/bin/linux/${ARCH}/kubelet > ${ROOTFS}/kubelet
  chmod +x ${ROOTFS}/kubelet
  echo "Installed kubelet."
else
  echo "Ignoring kubelet, since it seems to exist already"
fi

if [[ ! -f ${ROOTFS}/kubeadm ]]; then
  curl -sSL ${KUBEADM_URL}/${KUBEADM_RELEASE}/bin/linux/${ARCH}/kubeadm > ${ROOTFS}/kubeadm
  chmod +x ${ROOTFS}/kubeadm
  echo "Installed kubeadm."
else
  echo "Ignoring kubeadm, since it seems to exist already"
fi
