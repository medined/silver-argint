#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Usage: -f [configuration file] <namespace>"
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

unset DOMAIN_NAME

CONFIG_FILE=$2
NAMESPACE=$3
if [ ! -f $CONFIG_FILE ]; then
    echo "ERROR: Missing configuration file: $CONFIG_FILE"
    return
fi
source $CONFIG_FILE

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  return
fi

kubectl get namespace $NAMESPACE 1>/dev/null 2>&1
if [ $? != 0 ]; then
    echo "ERROR: Missing namespace: $NAMESPACE"
    echo "  Please run ./namespace-create.sh"
    exit
else
    echo "Namespace exists: $NAMESPACE"
fi

mkdir -p $HOME/bin
pushd $HOME/bin > /dev/null

ISTIO_VERSION="istio-1.5.0"

if [ -d $HOME/bin/$ISTIO_VERSION ]; then
    echo "istio already downloaded."
else
    curl -L https://istio.io/downloadIstio | sh -
    echo "istio downloaded."
fi

grep "$ISTIO_VERSION/bin" $HOME/.bashrc
if [ $? == 0 ]; then
  echo "PATH already updated."
else
  echo "export PATH=\$PATH:$(pwd)/$ISTIO_VERSION/bin" >> $HOME/.bashrc
  echo "PATH updated."
fi

kubectl get namespace istio-system 1>/dev/null 2>&1
if [ $? != 0 ]; then
    $ISTIO_VERSION/bin/istioctl verify-install
    echo
    echo "If the verify looks good, press <ENTER>. Otherwise ^C."
    read -p "Press <ENTER> to continue."
    echo
    $ISTIO_VERSION/bin/istioctl manifest apply --set profile=demo
    kubectl label namespace $NAMESPACE istio-injection=enabled
    kubectl label namespace default istio-injection=enabled
else
    echo "Istio already installed."
fi

popd > /dev/null

echo
echo "Istio is installed. If you need further help, see the 'Deploy the sample application'"
echo "section of https://istio.io/docs/setup/getting-started."
echo
echo "Run the following command to connect to the istio installation directory:"
echo 
echo "  pushd $HOME/bin/$ISTIO_VERSION"
