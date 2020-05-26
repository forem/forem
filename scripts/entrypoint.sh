#!/usr/bin/env bash

set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

echo "Running rake search:setup..."
bundle exec rake search:setup
echo "Running rake db:migrate..."
bundle exec rake db:migrate 2>/dev/null || bundle exec rake db:setup
echo "Running rake data_updates:run..."
bundle exec rake data_updates:run

exec "$@"
