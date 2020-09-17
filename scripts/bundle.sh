#!/usr/bin/env bash

set -e

if [ -f /opt/apps/bundle/bundle_finished ]; then
  rm -f /opt/apps/bundle/bundle_finished
fi

bundle install --local --jobs 20 --retry 5
echo $(date --utc +%FT%T%Z) > /opt/apps/bundle/bundle_finished
