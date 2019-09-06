module Audit
  module Event
    class Payload
      ##
      # Definition of Event payload.
      #
      # New instance object is used as block parameter in Audit::Notification.notify method.
      attr_accessor :user_id, :roles, :slug, :data

      ##
      # Use the initializer to define default values for the payload.

      def initialize
        @roles = []
        @slug = :undefined
        @data = {}

        yield(self)
      end
    end
  end
end
