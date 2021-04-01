#!/usr/bin/env bash

# Disable the Datadog Agent for scheduler workers
if [ "$DYNOTYPE" == "run" ]; then
  DISABLE_DATADOG_AGENT="true"
  # Disable Automatic Beeline integrations to prevent unnecessary
  # data from being tracked in Honeycomb
  # more info here: https://docs.honeycomb.io/getting-data-in/ruby/beeline/#using-env-variables-to-control-framework-integrations
  export HONEYCOMB_DISABLE_AUTOCONFIGURE="true"
  export HONEYCOMB_INTEGRATIONS=rails,rake,active_support
fi
