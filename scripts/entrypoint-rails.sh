#!/usr/bin/env bash

set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi
bin/setup
bundle exec rails server -b 0.0.0.0 -p 3000
