module Audit
  module Event
    class Payload
      ##
      # Definition of Event payload.
      #
      # New instance object is used as block parameter in Audit::Notification.notify method.
      attr_accessor :user_id, :roles

      ##
      # Use the initializer to define default values for the payload.
      def initialize(data = {})
        data.to_options!

        @user_id = data[:user_id]
        @roles = data[:roles] || []
      end

      class << self
        def empty
          Payload.new
        end
      end
    end
  end
end
