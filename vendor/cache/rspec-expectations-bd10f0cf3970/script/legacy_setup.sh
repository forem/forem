#!/bin/bash
# This file was generated on 2021-01-22T18:13:35+00:00 from the rspec-dev repo.
# DO NOT modify it by hand as your changes will get lost the next time it is generated.

set -e
source script/functions.sh

bundle install --standalone --binstubs --without coverage documentation

if [ -x ./bin/rspec ]; then
  echo "RSpec bin detected"
else
  if [ -x ./exe/rspec ]; then
    cp ./exe/rspec ./bin/rspec
    echo "RSpec restored from exe"
  else
    echo "No RSpec bin available"
    exit 1
  fi
fi
