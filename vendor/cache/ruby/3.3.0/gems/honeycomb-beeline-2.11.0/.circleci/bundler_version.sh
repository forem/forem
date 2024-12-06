#!/usr/bin/env bash

set -ux

if [[ "$BUNDLE_GEMFILE" =~ (rails_41.gemfile|rails_42.gemfile)$ ]]; then
  echo "Rails 4.1 and 4.2 require an old Bundler"
  gem uninstall -v '>= 2' -ax bundler
  gem install bundler -v '< 2'
else
  echo "Get the latest Bundler"
  gem update bundler
fi
