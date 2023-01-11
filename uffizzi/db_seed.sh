#!/usr/bin/env bash

bundle exec rake db:seed

tail -f /dev/null