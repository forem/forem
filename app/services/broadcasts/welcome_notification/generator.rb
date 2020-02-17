# Generates a broadcast to be delivered as a notification.
module Broadcasts
  module WelcomeNotification
    class Generator
      def initialize(receiver_id)
        @receiver_id = receiver_id
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        # This method should find the user based on the `receiver_id`.
        # It should then determine the appropriate Broadcast for a user,
        # based on the `created_at` and the different conditions for sending a notification.
        # `welcome_broadcast = ...`

        # Once it has the appropriate Broadcast to be sent, it should send a notification for it:
        # `Notification.send_welcome_notification(receiver_id, welcome_broadcast.id)`
        # welcome_broadcast = # Rubocop will NOT leave me alone and keeps throwing errors in this entire method, so this will have to stay like this for now
        return unless !has_commented_on_welcome_thread? && receiver_id == user.id # I feel like a check for the User's id is necessary here...

        # return unless !has_commented_on_welcome_thread? # I CANNOT believe I forgot to eveluate this statement before... :facepalm:

        Broadcast.find_by(title: "Welcome: welcome_thread") # Find the correct, welcome_thread in this case, Broadcast
        Notification.send_welcome_notification(receiver_id, welcome_broadcast.id) # send the welcome_notification once the appropriate Broadcast has been found...still working on this
        # end
      end

      def has_commented_on_welcome_thread?
        # byebug # My BFF again
        # articles.comments.commentable.where("title LIKE 'Welcome Thread - %'") && user.comments_count > 1
        articles.comments.commentable.where(["title = ?", "Welcome Thread"]) && user.comments_count > 1 # Still trying to figure out what to do here, but due to spec failures, I am having a hard time hitting byebug/pry to inspect these values and their returns
      end

      private

      attr_reader :receiver_id # Convention is good :)
    end
  end
end
