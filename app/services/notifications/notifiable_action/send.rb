# send notification about the action ("Published") that happened on a notifiable (Article)
module Notifications
  module NotifiableAction
    FOLLOWER_SEND_LIMIT = 10_000
    class Send
      def self.call(...)
        new(...).call
      end

      # @param notifiable [Article]
      # @param action [String] for now only "Published"
      def initialize(notifiable, action = nil)
        @notifiable = notifiable
        @action = action
      end

      delegate :user_data, :article_data, :organization_data, to: Notifications

      def call
        return unless notifiable.is_a?(Article)

        json_data = {
          user: user_data(notifiable.user),
          article: article_data(notifiable)
        }
        json_data[:organization] = organization_data(notifiable.organization) if notifiable.organization_id

        notifications_attributes = []

        # If a user was mentioned in the article, they will have already received a mention.
        # We explicitly need to exclude them from the article_followers array if they already
        # have a mention in order to avoid sending a user multiple notifications for one article.
        user_ids_with_article_mentions = notifiable.mentions&.pluck(:user_id)

        article_followers = User.joins("INNER JOIN follows ON follows.follower_id = users.id")
          .where("(follows.followable_id = ? AND follows.followable_type = ?)
                 OR (follows.followable_id = ? AND follows.followable_type = ?)",
                 notifiable&.user&.id, "User", notifiable&.organization&.id, "Organization")
          .where(follows: { subscription_status: "all_articles" })
          .where.not(id: (user_ids_with_article_mentions + [notifiable.user]))
          .recently_active(FOLLOWER_SEND_LIMIT).distinct

        article_followers.find_each do |follower|
          now = Time.current
          notifications_attributes.push(
            user_id: follower.id,
            notifiable_id: notifiable.id,
            notifiable_type: notifiable.class.name,
            subforem_id: notifiable.subforem_id,
            action: action,
            json_data: json_data,
            created_at: now,
            notified_at: now,
            updated_at: now,
          )
        end

        return if notifications_attributes.blank?

        upsert_index = choose_upsert_index(action)

        context_notification_attributes = {
          context_id: notifiable.id,
          context_type: notifiable.class.name,
          action: action
        }

        ActiveRecord::Base.transaction do
          Notification.upsert_all(
            notifications_attributes,
            unique_by: upsert_index,
            returning: %i[id],
          )

          ContextNotification.upsert(context_notification_attributes,
                                     unique_by: :index_context_notification_on_context_and_action)
        end
      end

      private

      attr_reader :notifiable, :action

      def choose_upsert_index(action)
        return :index_notifications_on_user_notifiable_and_action_not_null if action.present?

        :index_notifications_on_user_notifiable_action_is_null
      end
    end
  end
end
