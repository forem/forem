#!/usr/bin/env bash

bundle exec rake db:seed:staging

tail -f /dev/null
