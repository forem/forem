#!/usr/bin/env bash

set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

bundle exec rake search:setup
bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:setup
bundle exec rake data_updates:run

exec "$@"
