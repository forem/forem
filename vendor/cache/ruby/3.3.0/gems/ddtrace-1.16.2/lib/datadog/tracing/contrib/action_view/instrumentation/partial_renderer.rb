require_relative '../../../metadata/ext'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module ActionView
        module Instrumentation
          # Legacy instrumentation for partial rendering for Rails < 4
          module PartialRenderer
            def render(*args, &block)
              Tracing.trace(
                Ext::SPAN_RENDER_PARTIAL,
                span_type: Tracing::Metadata::Ext::HTTP::TYPE_TEMPLATE
              ) do |span|
                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_RENDER_PARTIAL)

                with_datadog_span(span) { super(*args) }
              end
            end

            def render_partial(*args)
              begin
                template = datadog_template(*args)

                datadog_render_partial(template)
              rescue StandardError => e
                Datadog.logger.debug(e.message)
              end

              # execute the original function anyway
              super(*args)
            end

            def datadog_render_partial(template)
              template_name = Utils.normalize_template_name(template.try('identifier'))

              if template_name
                active_datadog_span.resource = template_name
                active_datadog_span.set_tag(
                  Ext::TAG_TEMPLATE_NAME,
                  template_name
                )

                # Measure service stats
                Contrib::Analytics.set_measured(active_datadog_span)
              end
            end

            private

            attr_accessor :active_datadog_span

            def with_datadog_span(span)
              self.active_datadog_span = span
              yield
            ensure
              self.active_datadog_span = nil
            end

            # Rails < 4 partial rendering
            # ActiveSupport events are used instead for Rails >= 4
            module RailsLessThan4
              include PartialRenderer

              def datadog_template(*args)
                @template
              end
            end
          end
        end
      end
    end
  end
end
