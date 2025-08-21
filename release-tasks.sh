#!/bin/bash

notify () {
  FAILED_COMMAND="$(caller): ${BASH_COMMAND}" \
    bundle exec rails runner "ReleasePhaseNotifier.ping_slack"
}

trap notify ERR

# enable echo mode (-x) and exit on error (-e)
# -E ensures that ERR traps get inherited by functions, command substitutions, and subshell environments.
set -Eex

# abort release if deploy status equals "blocked"
[[ $DEPLOY_STATUS = "blocked" ]] && echo "Deploy blocked" && exit 1

# Validate Rails application can load without errors
echo "Validating Rails application initialization..."
bundle exec rails runner "puts 'Rails application loaded successfully'" || {
  echo "ERROR: Rails application failed to initialize"
  echo "This could be due to:"
  echo "  - Missing environment variables"
  echo "  - Database connection issues"
  echo "  - Initializer errors"
  echo "  - Gem dependency issues"
  exit 1
}

# Validate database connectivity and basic operations
echo "Validating database connectivity..."
bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" || {
  echo "ERROR: Database connectivity check failed"
  exit 1
}

# Update Fastly configurations
echo "Updating Fastly configurations..."
bundle exec rake fastly:update_configs

# Final validation - ensure the app can start successfully
echo "Final application validation..."
bundle exec rails runner "puts 'Application validation successful'"

echo "Release tasks completed successfully!"
