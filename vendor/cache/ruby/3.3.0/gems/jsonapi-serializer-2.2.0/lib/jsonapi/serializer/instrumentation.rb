require 'active_support/notifications'

module JSONAPI
  module Serializer
    # Support for instrumentation
    module Instrumentation
      # Performance instrumentation namespace
      NOTIFICATION_NAMESPACE = 'render.jsonapi-serializer.'.freeze

      # Patch methods to use instrumentation...
      %w[
        serializable_hash
        get_included_records
        relationships_hash
      ].each do |method_name|
        define_method(method_name) do |*args|
          ActiveSupport::Notifications.instrument(
            NOTIFICATION_NAMESPACE + method_name,
            { name: self.class.name, serializer: self.class }
          ) do
            super(*args)
          end
        end
      end
    end
  end
end
