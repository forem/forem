# frozen_string_literal: true

# Entrypoint file for auto instrumentation.
#
# This file's path is part of the @public_api.
require_relative '../ddtrace'
require_relative '../datadog/tracing/contrib/auto_instrument'

Datadog::Profiling.start_if_enabled

module Datadog
  module AutoInstrument
    # Flag to determine if Auto Instrumentation was used
    LOADED = true
  end
end
