#!/usr/bin/env bash
if [ $# -ne 3 ]; then
    echo "Illegal number of parameters"
    echo "Usage: $0 {client|server} <username> <ldap_password>"
    exit 1
fi

machine=$1

case $machine in  
  client)
    echo "Running $machine tests"
    username=$2 ldap_password=$3 bats ./p3d-$machine-tests.bats    
  ;;
  server)
    echo "Running $machine tests"
    username=$2 ldap_password=$3 bats ./p3d-$machine-tests.bats    
  ;;
  *)
     echo "Unkown option: $1"
  ;;
esac