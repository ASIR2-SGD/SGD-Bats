#!/usr/bin/env bash
if [ $# -ne 3 ]; then
    echo "Illegal number of parameters"
    echo "Usage: $0 {lan|fw|wan} vm_wan_ip"
    exit 1
fi

target=$1
vm_wan_ip=$2

case $machine in  
  lan)
    echo "Running $machine tests"
    bats ./firewall-$machine-tests.bats    
  ;;
  fw)
    echo "Running $machine tests"
    bats ./firewall-$machine-tests.bats    
  ;;
  wan)
    echo "Running $machine tests"
    wan_ip=$vm_wan_ip bats ./firewall-$machine-tests.bats    
  ;;
  *)
     echo "Unkown option: $1"
  ;;
esac