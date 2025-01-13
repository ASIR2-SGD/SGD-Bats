#!/usr/bin/env bash

#with sudo
#Install bats from npm

npm  install -g bats
mkdir -p /usr/lib/bats && cd /usr/lib/bats
git submodule add https://github.com/bats-core/bats-support.git test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git test_helper/bats-file


