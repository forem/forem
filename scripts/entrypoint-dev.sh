#!/usr/bin/env bash

set -e

if [ "$RAILS_ENV" = "test" ]; then
  bundle exec rake db:schema:load

  exec "$@"
else
  if [ -f tmp/pids/server.pid ]; then
    rm -f tmp/pids/server.pid
  fi

  export RELEASE_FOOTPRINT=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  export FOREM_BUILD_DATE=$(cat FOREM_BUILD_DATE)
  export FOREM_BUILD_SHA=$(cat FOREM_BUILD_SHA)

  echo "Running rake app_initializer:setup..."
  bundle exec rake app_initializer:setup

  exec "$@"
fi
