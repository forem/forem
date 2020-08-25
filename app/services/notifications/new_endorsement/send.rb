# send notifications about the new endorsement

module Notifications
  module NewEndorsement
    class Send
      def initialize(endorsement)
        @endorsement = endorsement
      end

      delegate :user_data, :endorsement_data, to: Notifications

      def self.call(*args)
        new(*args).call
      end

      def call
        json_data = {
          user: user_data(endorsement.user),
          endorsement: endorsement_data(endorsement)
        }

        targets = []
        user_id = current_user.id

        Notification.create(
          user_id: user_id,
          notifiable_id: endorsement.id,
          notifiable_type: endorsement.class.name,
          action: nil,
          json_data: json_data,
        )

        targets << "user-notifications-#{user_id}" if User.find_by(id: user_id)

        # Sends the push notification to Pusher Beams channels. Batch is in place to respect Pusher 100 channel limit.
        targets.each_slice(100) { |batch| PushNotifications::Send.call(batch, endorsement) }
      end

      private

      attr_reader :endorsement
    end
  end
end
