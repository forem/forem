# NOTE: [Rails 6] Util class is obsolete in Rails 6
module Audit
  module Event
    class Util
      class << self
        ##
        # These class methods are only used to serialize the object send toward
        # ActiveJob. Up until Rails 6, Rails cannot serialize Time objects,
        # therefore we need custom serialization.
        #
        # Additional method is used as Warning, which helps to notify when it is
        # save to remove this custom serialization for ActiveSupport::Notifications::Event object
        # more at: https://edgeapi.rubyonrails.org/classes/ActiveJob/Serializers/ObjectSerializer.html
        # and https://edgeapi.rubyonrails.org/classes/ActiveJob/SerializationError.html
        # for supported class instances

        def deserialize(string)
          obsolete_usage_warn

          transform_values(string).
            then { |obj| ActiveSupport::Notifications::Event.new(*obj) }
        end

        def serialize(event)
          obsolete_usage_warn

          ActiveSupport::JSON.encode event
        end

        private

        def obsolete_usage_warn
          warn_message = <<-WARN.strip_heredoc
            This Util class becomes obsolete from Rails 6.
            Rails 6 adds out of the box, support for Active Job message serialization
            for class like Time.

            You can save delete this Util class and remove the usage from
            Audit::Notification.listen method, or in any other places
          WARN

          Rails.logger.warn(warn_message) if Rails.version.match?(/\A6.\d.\w+/)
        end

        def transform_values(string)
          ActiveSupport::JSON.decode(string).deep_symbolize_keys.tap do |h|
            h[:time] = Time.zone.iso8601(h[:time])
            h[:end] = Time.zone.iso8601(h[:end])
          end.values_at(:name, :time, :end, :transaction_id, :payload)
        end
      end
    end
  end
end
