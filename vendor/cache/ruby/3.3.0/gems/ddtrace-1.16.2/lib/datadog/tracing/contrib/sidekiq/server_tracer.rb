# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative 'utils'
require_relative '../utils/quantization/hash'
require_relative 'distributed/propagation'

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        # Tracer is a Sidekiq server-side middleware which traces executed jobs
        class ServerTracer
          include Utils

          QUANTIZE_SHOW_ALL = { args: { show: :all } }.freeze

          def initialize(options = {})
            @sidekiq_service = options[:service_name] || configuration[:service_name]
            @error_handler = options[:error_handler] || configuration[:error_handler]
          end

          # rubocop:disable Metrics/MethodLength
          # rubocop:disable Metrics/AbcSize
          def call(worker, job, queue)
            resource = job_resource(job)

            if configuration[:distributed_tracing]
              trace_digest = propagation.extract(job)
              Datadog::Tracing.continue_trace!(trace_digest)
            end

            service = worker_config(resource, :service_name) || @sidekiq_service
            # DEV-2.0: Remove `tag_args`, as `quantize` can fulfill the same contract
            tag_args = worker_config(resource, :tag_args) || configuration[:tag_args]
            quantize = worker_config(resource, :quantize) || configuration[:quantize]

            Datadog::Tracing.trace(
              Ext::SPAN_JOB,
              service: service,
              span_type: Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER,
              on_error: @error_handler
            ) do |span|
              span.resource = resource

              span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_COMPONENT)

              span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_JOB)

              span.set_tag(
                Datadog::Tracing::Metadata::Ext::TAG_KIND,
                Datadog::Tracing::Metadata::Ext::SpanKind::TAG_CONSUMER
              )

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(span)

              span.set_tag(Ext::TAG_JOB_ID, job['jid'])
              span.set_tag(Ext::TAG_JOB_RETRY, job['retry'])
              span.set_tag(Ext::TAG_JOB_RETRY_COUNT, job['retry_count'])
              span.set_tag(Ext::TAG_JOB_QUEUE, job['queue'])
              span.set_tag(Ext::TAG_JOB_WRAPPER, job['class']) if job['wrapped']
              span.set_tag(Ext::TAG_JOB_DELAY, 1000.0 * (Time.now.utc.to_f - job['enqueued_at'].to_f))

              args = job['args']
              if args && !args.empty?
                quantize = tag_args ? QUANTIZE_SHOW_ALL : quantize
                span.set_tag(Ext::TAG_JOB_ARGS, quantize_args(quantize, args))
              end

              yield
            end
            # rubocop:enable Metrics/MethodLength
            # rubocop:enable Metrics/AbcSize
          end

          private

          def propagation
            @propagation ||= Contrib::Sidekiq::Distributed::Propagation.new
          end

          def quantize_args(quantize, args)
            quantize_options = quantize && quantize[:args]
            quantize_options ||= {}

            Contrib::Utils::Quantization::Hash.format(args, quantize_options)
          end

          def configuration
            Datadog.configuration.tracing[:sidekiq]
          end

          # DEV-2.0: Is this still being used? If not, we should remove it
          # as this adds brittleness and complexity to this integration.
          def worker_config(resource, key)
            # Try to get the Ruby class from the resource name.
            worker_klass = begin
              Object.const_get(resource)
            rescue NameError
              nil
            end

            worker_klass.datadog_tracer_config[key] if worker_klass.respond_to?(:datadog_tracer_config)
          end
        end
      end
    end
  end
end
