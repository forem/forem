# Removes co-author notifications for users who are no longer credited.
module Notifications
  module CoAuthor
    class Remove
      def self.call(...)
        new(...).call
      end

      # @param article_id [Integer]
      # @param user_ids [Array<Integer>]
      def initialize(article_id, user_ids)
        @article_id = article_id
        @user_ids = Array.wrap(user_ids).map(&:to_i)
      end

      def call
        return if user_ids.empty?

        recipients = Notification.where(
          user_id: user_ids,
          notifiable_id: article_id,
          notifiable_type: "Article",
          action: Notifications::CoAuthor::Send::ACTION,
        ).pluck(:user_id, :id).to_h
        removed = Notification.where(id: recipients.values).delete_all
        return removed unless removed.positive?

        Notifications::SyncEvents.removed(
          notifiable_type: "Article",
          notifiable_ids: [article_id],
          action: Notifications::CoAuthor::Send::ACTION,
          recipients: recipients,
          reason: "co_author_removed",
        )
        removed
      end

      private

      attr_reader :article_id, :user_ids
    end
  end
end
