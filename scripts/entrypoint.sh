#!/usr/bin/env bash

set -e

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

export RELEASE_FOOTPRINT=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

if [[ "${RAILS_ENV}" = "development" || "${RAILS_ENV}" = "test" ]]; then

  export FOREM_BUILD_DATE="${RELEASE_FOOTPRINT}"
  export FOREM_BUILD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unspecified")

else

  export FOREM_BUILD_DATE=$([ -f FOREM_BUILD_DATE ] && cat FOREM_BUILD_DATE || echo "${RELEASE_FOOTPRINT}")
  export FOREM_BUILD_SHA=$([ -f FOREM_BUILD_SHA ] && cat FOREM_BUILD_SHA || echo "unspecified")

fi

prepare_database_if_requested() {
  if [[ "${AUTO_PREPARE_DB:-false}" != "true" ]]; then
    return 0
  fi

  if [[ -n "${DATABASE_URL:-}" ]] && command -v pg_isready >/dev/null 2>&1; then
    local attempts=0
    until pg_isready -d "${DATABASE_URL}" >/dev/null 2>&1 || [[ ${attempts} -ge 30 ]]; do
      attempts=$((attempts + 1))
      echo "Waiting for PostgreSQL (${attempts}/30)..."
      sleep 1
    done
  fi

  local redis_check_url="${REDIS_SIDEKIQ_URL:-${REDIS_URL:-}}"
  if [[ -n "${redis_check_url}" ]]; then
    bundle exec ruby -rredis -e '
      url = ENV["REDIS_SIDEKIQ_URL"].to_s
      url = ENV["REDIS_URL"].to_s if url.empty?
      30.times do |i|
        begin
          break if Redis.new(url: url, timeout: 2).ping == "PONG"
        rescue StandardError
          warn "Waiting for Redis (#{i + 1}/30)..."
          sleep 1
        end
      end
    ' || true
  fi

  echo "Running app_initializer:setup (AUTO_PREPARE_DB=true)..."
  STATEMENT_TIMEOUT=4500000 bundle exec rails app_initializer:setup
}

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
    case "$*" in
      *bin/web*|*puma*|*"rails server"*)
        prepare_database_if_requested
        ;;
    esac
    echo "Running command:"
    echo "$@"
    exec "$@"
    ;;

esac
