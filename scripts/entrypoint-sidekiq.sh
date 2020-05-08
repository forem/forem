#!/bin/sh

set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

bundle exec sidekiq -c 2
