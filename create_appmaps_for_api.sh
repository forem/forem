#!/bin/sh

# Create AppMaps for api/v1
APPMAP=true RAILS_ENV=test bundle exec rspec ./spec/requests/api/v1
