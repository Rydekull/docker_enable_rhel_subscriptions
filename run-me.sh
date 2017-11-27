#!/bin/bash
if [ "$1" = "-v" ]
then
  VERBOSITY="-vv"
elif [ "$1" = "-d" ]
then
  VERBOSITY="-vvv"
fi

export ANSIBLE_STDOUT_CALLBACK=dense ; ansible-playbook -i 127.0.0.1, -c local playbook.yml ${VERBOSITY}

if [ $? != 0 ]
then
  echo "Something went wrong, please reexecute me with one of the following options:"
  echo "  -v    verbose"
  echo "  -d    debug" 
  echo
  echo "Example: bash $(basename $0) -v # For slightly more verbose output"
fi
