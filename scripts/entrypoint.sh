#!/usr/bin/env bash

set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

export RELEASE_FOOTPRINT=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

if [[ "${RAILS_ENV}" = "development" || "${RAILS_ENV}" = "test" ]]; then

  export FOREM_BUILD_DATE=RELEASE_FOOTPRINT
  export FOREM_BUILD_SHA=$(git rev-parse --short HEAD)

else

  export FOREM_BUILD_DATE=$(cat FOREM_BUILD_DATE)
  export FOREM_BUILD_SHA=$(cat FOREM_BUILD_SHA)

fi

case "$@" in

  precompile)
    echo "Running rake assets:precompile..."
    bundle exec rake assets:precompile
    ;;

  clean)
    echo "Running rake assets:clean..."
    bundle exec rake assets:clean
    ;;

  clobber)
    echo "Running rake assets:clobber..."
    bundle exec rake assets:clobber
    ;;

  bootstrap)
    echo "Running rake app_initializer:setup..."
    bundle exec rake app_initializer:setup
    ;;

  *)
    echo "Running command:"
    echo "$@"
    exec "$@"
    ;;

esac
