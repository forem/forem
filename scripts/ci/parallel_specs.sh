#!/bin/bash

set -euo pipefail

cp .env_sample .env

# if [ "$KNAPSACK_PRO_TEST_SUITE_TOKEN_RSPEC" = "" ]; then
  KNAPSACK_PRO_ENDPOINT=https://api-disabled-for-fork.knapsackpro.com \
    KNAPSACK_PRO_MAX_REQUEST_RETRIES=0 \
    KNAPSACK_PRO_TEST_SUITE_TOKEN_RSPEC=disabled-for-fork \
    rake knapsack_pro:rspec # use Regular Mode here always
# else
#   rake knapsack_pro:queue:rspec
# fi
