#!/bin/bash

# enable echo mode
set -x

# abort release if deploy status equals "blocked"
[[ $DEPLOY_STATUS = "blocked" ]] && echo "Deploy blocked" && exit 1

# runs migration for Postgres, setups/updates Elasticsearch
# and boots the app to check there are no errors
STATEMENT_TIMEOUT=180000 bundle exec rails db:migrate && \
  bundle exec rake search:setup && \
  bundle exec rake data_updates:enqueue_data_update_worker && \
  bundle exec rails runner "puts 'app load success'"
