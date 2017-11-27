#!/bin/bash
/usr/bin/subscription-manager register --org $RH_ORG --activationkey $RH_ACTIVATIONKEY
if [ $? != 0 ]
then
  cat /var/log/rhsm/rhsm.log >> /deploy/log.txt
  echo failure
  exit 1
fi
