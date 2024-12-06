# frozen_string_literal: true

require 'opentracing'
require 'opentracing/carrier'
require_relative 'tracing'

require_relative 'opentracer/carrier'
require_relative 'opentracer/tracer'
require_relative 'opentracer/span'
require_relative 'opentracer/span_context'
require_relative 'opentracer/span_context_factory'
require_relative 'opentracer/scope'
require_relative 'opentracer/scope_manager'
require_relative 'opentracer/thread_local_scope'
require_relative 'opentracer/thread_local_scope_manager'
require_relative 'opentracer/distributed_headers'
require_relative 'opentracer/propagator'
require_relative 'opentracer/text_map_propagator'
require_relative 'opentracer/binary_propagator'
require_relative 'opentracer/rack_propagator'
require_relative 'opentracer/global_tracer'

# Modify the OpenTracing module functions
::OpenTracing.singleton_class.prepend(Datadog::OpenTracer::GlobalTracer)

module Datadog
  # Datadog OpenTracing integration.
  # DEV: This module should be named `Datadog::OpenTracing` to match the gem (`opentracing`).
  module OpenTracer
    # Used by Telemetry to decide if OpenTracing instrumentation is enabled
    LOADED = true
  end
end
