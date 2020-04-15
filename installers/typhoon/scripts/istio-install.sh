#!/bin/bash

mkdir -p $HOME/bin
pushd $HOME/bin > /dev/null

ISTIO_VERSION="istio-1.5.1"

if [ -d $HOME/bin/$ISTIO_VERSION ]; then
    echo "istio already downloaded."
else
    curl -L https://istio.io/downloadIstio | sh -
    echo "istio downloaded."
fi

# Istio has been downloaded. If the expected directory does not
# exist, then the version has probably changed.

if [ ! -d $HOME/bin/$ISTIO_VERSION ]; then
    echo "The istio version has probably changed. Check $HOME/bin and fix this script."
    exit
fi

cat <<EOF | sudo tee /etc/profile.d/istio-config.sh
export PATH=\$PATH:$HOME/bin/$ISTIO_VERSION/bin
EOF
export PATH=$PATH:$HOME/bin/$ISTIO_VERSION/bin

kubectl get namespace istio-system 1>/dev/null 2>&1
if [ $? != 0 ]; then
    $ISTIO_VERSION/bin/istioctl verify-install
    echo
    echo "If the verify looks good, press <ENTER>. Otherwise ^C."
    read -p "Press <ENTER> to continue."
    echo
    $ISTIO_VERSION/bin/istioctl manifest apply --set profile=demo
    kubectl label namespace default istio-injection=enabled
else
    echo "Istio already installed."
fi

popd > /dev/null

echo
echo "Istio is installed. If you need further help, see the 'Deploy the sample application'"
echo "section of https://istio.io/docs/setup/getting-started."
echo
echo "Istio has been downloaded to $HOME/bin. Version $ISTIO_VERSION is being used. Below"
echo "are the installed versions. If you see something newer, update this script and take"
echo "the neccessary steps to upgrade."
echo
ls -ld $HOME/bin/istio*
echo
echo "Enable each namespace that Istio should montor with the following command:"
echo
echo "    kubectl label namespace $NAMESPACE istio-injection=enabled"
echo
echo "Run the following command to connect to the istio installation directory:"
echo 
echo "  pushd $HOME/bin/$ISTIO_VERSION"
