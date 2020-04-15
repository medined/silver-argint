#!/bin/bash

NAMESPACE=${1:-sandbox}
NAME=jenkins

ps f | grep "kubectl --namespace $NAMESPACE port-forward $NAME" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  PID=$(ps f | grep "kubectl --namespace $NAMESPACE port-forward $NAME" | grep -v grep | awk '{print $1}')
  kill $PID
  echo "Killed process: $PID"
fi

ps faux | grep "kubectl --namespace $NAMESPACE port-forward $NAME" | grep -v grep > /dev/null
if [ $? == 0 ]; then
  echo "ERROR: Unable to kill jenkins proxy."
else
  echo "Jenkins proxy is gone."
fi
