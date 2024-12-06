require_relative '../../../metadata/ext'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module ActionView
        module Instrumentation
          # Legacy instrumentation for template rendering for Rails < 4
          module TemplateRenderer
            # Legacy shared code for Rails >= 3.1 template rendering
            module Rails31Plus
              def render(*args, &block)
                Tracing.trace(
                  Ext::SPAN_RENDER_TEMPLATE,
                  span_type: Tracing::Metadata::Ext::HTTP::TYPE_TEMPLATE
                ) do |span|
                  span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                  span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_RENDER_TEMPLATE)

                  with_datadog_span(span) { super(*args, &block) }
                end
              end

              def render_template(*args)
                begin
                  template, layout_name = datadog_parse_args(*args)

                  datadog_render_template(template, layout_name)
                rescue StandardError => e
                  Datadog.logger.debug(e.message)
                end

                # execute the original function anyway
                super(*args)
              end

              def datadog_render_template(template, layout_name)
                # update the tracing context with computed values before the rendering
                template_name = template.try('identifier')
                template_name = Utils.normalize_template_name(template_name)
                layout = layout_name.try(:[], 'virtual_path') # Proc can be called without parameters since Rails 6

                if template_name
                  active_datadog_span.resource = template_name
                  active_datadog_span.set_tag(
                    Ext::TAG_TEMPLATE_NAME,
                    template_name
                  )
                end

                if layout
                  active_datadog_span.set_tag(
                    Ext::TAG_LAYOUT,
                    layout
                  )
                end

                # Measure service stats
                Contrib::Analytics.set_measured(active_datadog_span)
              end

              private

              attr_accessor :active_datadog_span

              def with_datadog_span(span)
                self.active_datadog_span = span
                yield
              ensure
                self.active_datadog_span = nil
              end
            end

            # Rails >= 3.1, < 4 template rendering
            # ActiveSupport events are used instead for Rails >= 4
            module RailsLessThan4
              include Rails31Plus

              def datadog_parse_args(template, layout_name, *args)
                [template, layout_name]
              end
            end
          end
        end
      end
    end
  end
end
