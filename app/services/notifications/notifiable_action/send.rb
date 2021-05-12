# send notification about the action ("Published") that happened on a notifiable (Article)
module Notifications
  module NotifiableAction
    class Send
      # @param notifiable [Article]
      # @param action [String] for now only "Published"
      def initialize(notifiable, action = nil)
        @notifiable = notifiable
        @action = action
      end

      delegate :user_data, :article_data, :organization_data, to: Notifications

      def self.call(...)
        new(...).call
      end

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
        article_followers = notifiable.followers.reject do |follower|
          user_ids_with_article_mentions.include?(follower.id)
        end

        article_followers.sort_by(&:updated_at).last(10_000).reverse_each do |follower|
          now = Time.current
          notifications_attributes.push(
            user_id: follower.id,
            notifiable_id: notifiable.id,
            notifiable_type: notifiable.class.name,
            action: action,
            json_data: json_data,
            created_at: now,
            notified_at: now,
            updated_at: now,
          )
        end

        return if notifications_attributes.blank?

        upsert_index = choose_upsert_index(action)
        Notification.upsert_all(
          notifications_attributes,
          unique_by: upsert_index,
          returning: %i[id],
        )
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
