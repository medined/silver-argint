#!/bin/bash

NAMESPACE=sandbox
NAME=jenkins

ps f | grep "kubectl --namespace sandbox port-forward jenkins" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  PID=$(ps f | grep "kubectl --namespace sandbox port-forward jenkins" | grep -v grep | cut -d' ' -f1)
  kill $PID
fi

ps faux | grep "kubectl --namespace sandbox port-forward jenkins" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "##########################################"
  echo "# FAILURE: Unable to kill jenkins proxy. #"
  echo "##########################################"
else
  echo "###################################"
  echo "# SUCCESS: Jenkins proxy is gone. #"
  echo "###################################"
fi