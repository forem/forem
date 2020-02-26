#!/bin/bash

action () {
  "$@"
  local status=$?

  # Test the exit status of the command run
  # and display an error message on failure
  if test ${status} -ne 0
  then
      FAILED_COMMAND="$@" bundle exec rails runner "ReleasePhaseNotifier.ping_slack"
      exit 1
  fi

  return ${status}
}

# enable echo mode
set -x

# abort release if deploy status equals "blocked"
[[ $DEPLOY_STATUS = "blocked" ]] && echo "Deploy blocked" && exit 1

# runs migration for Postgres, setups/updates Elasticsearch
# and boots the app to check there are no errors
STATEMENT_TIMEOUT=180000 action bundle exec rails db:migrate # && \
action bundle exec rake search:setup #&& \
action bundle exec rake data_updates:enqueue_data_update_worker #&& \
action bundle exec rails runner "puts 'app load success'"
