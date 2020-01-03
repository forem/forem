#!/usr/bin/env bash

# Disable the Datadog Agent for scheduler workers
if [ "$DYNOTYPE" == "scheduler" ] || [ "$DYNOTYPE" == "run" ]; then
  DISABLE_DATADOG_AGENT="true"
fi
