#!/usr/bin/env bash
if [ $# -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Usage: $0 <username>"
    exit 1
fi


username=$1 bats ./radius-tests.bats