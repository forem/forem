#!/usr/bin/env bash

SEEDS_MULTIPLIER=3 bundle exec rake db:seed:staging

tail -f /dev/null
