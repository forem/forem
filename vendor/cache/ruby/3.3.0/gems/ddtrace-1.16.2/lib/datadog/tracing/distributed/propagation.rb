# frozen_string_literal: true

require_relative '../configuration/ext'
require_relative '../trace_digest'
require_relative '../trace_operation'

module Datadog
  module Tracing
    module Distributed
      # Provides extraction and injection of distributed trace data.
      class Propagation
        # DEV: This class should receive the value for
        # DEV: `Datadog.configuration.tracing.distributed_tracing.propagation_inject_style`
        # DEV: at initialization time, instead of constantly reading global values.
        # DEV: This means this class should be reconfigured on `Datadog.configure` calls, thus
        # DEV: singleton instances should not used as they will become stale.
        #
        # @param propagation_styles [Hash<String,Object>]
        def initialize(propagation_styles:)
          @propagation_styles = propagation_styles
          # We need to make sure propagation_style option is evaluated.
          # Our options are lazy evaluated and it happens that propagation_style has the after_set callback
          # that affect Datadog.configuration.tracing.distributed_tracing.propagation_inject_style and
          # Datadog.configuration.tracing.distributed_tracing.propagation_extract_style
          # By calling it here, we make sure if the customers has set any value either via code or ENV variable is applied.
          ::Datadog.configuration.tracing.distributed_tracing.propagation_style
        end

        # inject! populates the env with span ID, trace ID and sampling priority
        #
        # This method will never raise errors, but instead log them to `Datadog.logger`.
        #
        # DEV-2.0: inject! should work without arguments, injecting the active_trace's digest
        # DEV-2.0: and returning a new Hash with the injected data.
        # DEV-2.0: inject! should also accept either a `trace` or a `digest`, as a `trace`
        # DEV-2.0: argument is the common use case, but also allows us to set error tags in the `trace`
        # DEV-2.0: if needed.
        # DEV-2.0: Ideally, we'd have a separate stream to report tracer errors and never
        # DEV-2.0: touch the active span.
        #
        # @param digest [TraceDigest]
        # @param data [Hash]
        # @return [Boolean] `true` if injected successfully, `false` if no propagation style is configured
        # @return [nil] in case of error, see `Datadog.logger` output for details.
        def inject!(digest, data)
          if digest.nil?
            ::Datadog.logger.debug('Cannot inject distributed trace data: digest is nil.')
            return nil
          end

          digest = digest.to_digest if digest.respond_to?(:to_digest)

          result = false

          # Inject all configured propagation styles
          ::Datadog.configuration.tracing.distributed_tracing.propagation_inject_style.each do |style|
            propagator = @propagation_styles[style]
            begin
              if propagator
                propagator.inject!(digest, data)
                result = true
              end
            rescue => e
              result = nil
              ::Datadog.logger.error(
                "Error injecting distributed trace data. Cause: #{e} Location: #{Array(e.backtrace).first}"
              )
            end
          end

          result
        end

        # extract returns {TraceDigest} containing the distributed trace information.
        # sampling priority defined in data.
        #
        # This method will never raise errors, but instead log them to `Datadog.logger`.
        #
        # @param data [Hash]
        def extract(data)
          return unless data
          return if data.empty?

          extracted_trace_digest = nil

          ::Datadog.configuration.tracing.distributed_tracing.propagation_extract_style.each do |style|
            propagator = @propagation_styles[style]
            next if propagator.nil?

            begin
              extracted_trace_digest = propagator.extract(data)
            rescue => e
              ::Datadog.logger.error(
                "Error extracting distributed trace data. Cause: #{e} Location: #{Array(e.backtrace).first}"
              )
            end

            break if extracted_trace_digest
          end

          extracted_trace_digest
        end
      end
    end
  end
end
