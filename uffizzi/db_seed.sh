#!/usr/bin/env bash

SEEDS_MULTIPLIER=2 bundle exec rake db:seed:staging

tail -f /dev/null
