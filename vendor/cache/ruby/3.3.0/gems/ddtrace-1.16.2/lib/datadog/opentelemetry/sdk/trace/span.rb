# frozen_string_literal: true

module Datadog
  module OpenTelemetry
    module Trace
      # Stores associated Datadog entities to the OpenTelemetry Span.
      module Span
        # Attributes are equivalent to span tags and metrics.
        def set_attribute(key, value)
          res = super
          # Attributes can get dropped or their values truncated by `super`
          datadog_set_attribute(key)
          res
        end

        # `alias` performed to match {OpenTelemetry::SDK::Trace::Span} aliasing upstream
        alias []= set_attribute

        # Attributes are equivalent to span tags and metrics.
        def add_attributes(attributes)
          res = super
          # Attributes can get dropped or their values truncated by `super`
          attributes.each { |key, _| datadog_set_attribute(key) }
          res
        end

        # Captures changes to span error state.
        def status=(s)
          super

          return unless status # Return if status are currently disabled by OpenTelemetry.
          return unless (span = datadog_span)

          # Status code can only change into an error state.
          # Other change operations should be ignored.
          span.set_error(status.description) if status && status.code == ::OpenTelemetry::Trace::Status::ERROR
        end

        private

        def datadog_set_attribute(key)
          # Return if attributes are currently disabled by OpenTelemetry.
          return unless defined?(@attributes) && @attributes
          return unless (span = datadog_span)

          # DEV: Accesses `@attributes` directly, since using `#attributes`
          # DEV: clones the hash, causing unnecessary overhead.
          if @attributes.key?(key)
            value = @attributes[key]
            span.set_tag(key, value)

            span.service = value if key == 'service.name'
          else
            span.clear_tag(key)

            if key == 'service.name'
              # By removing the service name, we set it to the fallback default,
              # effectively removing the `service` attribute from OpenTelemetry's perspective.
              span.service = Datadog.send(:components).tracer.default_service
            end
          end
        end

        ::OpenTelemetry::SDK::Trace::Span.prepend(self)
      end
    end
  end
end
