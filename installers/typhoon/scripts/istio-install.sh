#!/bin/bash

BDIR=$1

if [ -z $BDIR ]; then
  echo "Please supply the bin (/data/bin) install directory."
  exit
fi

if [ ! -d $BDIR ]; then
  echo "Please create the bin directory: $BDIR"
  exit
fi

pushd $BDIR > /dev/null

ISTIO_VERSION="istio-1.6.0"

if [ -d ./$ISTIO_VERSION ]; then
    echo "istio already downloaded."
else
    curl -L https://istio.io/downloadIstio | sh -
    echo "istio downloaded."
fi

RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Using SUDO to update future shell invokations so that"
echo -e "${RED}istioctl${NC} can be used."
echo "------"

cat <<EOF | sudo tee /etc/profile.d/istio-config.sh
export PATH=\$PATH:$BDIR/$ISTIO_VERSION/bin
EOF

# Putting istio at the front of the path in case a different
# version was already installed.
export PATH=$BDIR/$ISTIO_VERSION/bin:$PATH

kubectl get namespace istio-system 1>/dev/null 2>&1
if [ $? != 0 ]; then
    istioctl manifest apply \
      --set components.cni.enabled=true \
      --set values.cni.cniConfDir=/etc/kubernetes/cni/net.d \
      --set profile=demo
else
    echo "Istio already installed."
fi

popd > /dev/null

echo
echo "Istio is installed. If you need further help, see the 'Deploy the sample application'"
echo "section of https://istio.io/docs/setup/getting-started."
echo
echo "Istio has been downloaded to $HOME/bin. Version $ISTIO_VERSION is being used."
echo
echo "Enable each namespace that Istio should montor with the following command:"
echo
echo "    kubectl label namespace $NAMESPACE istio-injection=enabled"
echo
echo "Run the following command to connect to the istio installation directory:"
echo
echo "  pushd $HOME/bin/$ISTIO_VERSION"
