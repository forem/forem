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
        json_data = {
          user: user_data(notifiable.user),
          article: article_data(notifiable)
        }
        json_data[:organization] = organization_data(notifiable.organization) if notifiable.organization_id

        notifications_attributes = []
        # followers is an array and not an activerecord object
        # followers can occasionally be nil because orphaned follows can possibly exist in the db (for now)
        followers.sort_by(&:updated_at).reverse[0..10_000].each do |follower|
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

      def followers
        followers = notifiable.user.followers_scoped.where(subscription_status: "all_articles").map(&:follower)

        if notifiable.organization_id
          org_followers = notifiable.organization.followers_scoped.where(subscription_status: "all_articles")
          followers += org_followers.map(&:follower)
        end

        followers.uniq.compact
      end

      def choose_upsert_index(action)
        return :index_notifications_on_user_notifiable_and_action_not_null if action.present?

        :index_notifications_on_user_notifiable_action_is_null
      end
    end
  end
end
