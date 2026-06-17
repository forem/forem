module Notifications
  module EventNotification
    class Send
      def self.call(...)
        new(...).call
      end

      def initialize(signup, time_frame)
        @signup = signup
        @time_frame = time_frame
      end

      delegate :user_data, to: Notifications

      def call
        event = signup.event
        user_for_pic = event.user || User.mascot_account || signup.user

        event_payload = {
          id: event.id,
          title: event.title,
          event_name_slug: event.event_name_slug,
          event_variation_slug: event.event_variation_slug
        }

        json_data = {
          user: user_data(user_for_pic),
          event: event_payload,
          time: time_frame
        }

        Notification.create!(
          user_id: signup.user_id,
          notifiable_id: event.id,
          notifiable_type: "Event",
          action: "reminder",
          json_data: json_data
        )
      end

      private

      attr_reader :signup, :time_frame
    end
  end
end
