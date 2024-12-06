require 'qless'

require_relative '../../metadata/ext'
require_relative '../analytics'

module Datadog
  module Tracing
    module Contrib
      module Qless
        # Uses Qless job hooks to create traces
        module QlessJob
          def around_perform(job)
            return super unless datadog_configuration && Tracing.enabled?

            Tracing.trace(Ext::SPAN_JOB, **span_options) do |span|
              span.resource = job.klass_name
              span.span_type = Tracing::Metadata::Ext::AppTypes::TYPE_WORKER
              span.set_tag(Ext::TAG_JOB_ID, job.jid)
              span.set_tag(Ext::TAG_JOB_QUEUE, job.queue_name)

              tag_job_tags = datadog_configuration[:tag_job_tags]
              span.set_tag(Ext::TAG_JOB_TAGS, job.tags) if tag_job_tags

              tag_job_data = datadog_configuration[:tag_job_data]
              if tag_job_data && !job.data.empty?
                job_data = job.data.with_indifferent_access
                formatted_data = job_data.except(:tags).map do |key, value|
                  "#{key}:#{value}".underscore
                end

                span.set_tag(Ext::TAG_JOB_DATA, formatted_data)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_JOB)
              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CONSUMER)

              span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_COMPONENT)

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, datadog_configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(span)

              super
            end
          end

          def after_fork
            configuration = Datadog.configuration.tracing[:qless]
            return if configuration.nil?

            # Add a pin, marking the job as forked.
            # Used to trigger shutdown in forks for performance reasons.
            # Cleanup happens in the TracerCleaner class
            Datadog.configure_onto(::Qless, forked: true)
          end

          private

          def span_options
            { service: datadog_configuration[:service_name] }
          end

          def datadog_configuration
            Datadog.configuration.tracing[:qless]
          end
        end
      end
    end
  end
end
