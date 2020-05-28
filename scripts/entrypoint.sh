#!/usr/bin/env bash

set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

echo "Running rake app_initializer:setup..."
bundle exec rake app_initializer:setup

exec "$@"
