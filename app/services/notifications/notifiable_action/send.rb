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

      def self.call(*args)
        new(*args).call
      end

      def call
        json_data = {
          user: user_data(notifiable.user),
          article: article_data(notifiable)
        }
        json_data[:organization] = organization_data(notifiable.organization) if notifiable.organization_id
        notifications = []
        # followers is an array and not an activerecord object
        # followers can occasionally be nil because orphaned follows can possibly exist in the db (for now)
        followers.sort_by(&:updated_at).reverse[0..10_000].each do |follower|
          notifications.push Notification.new(
            user_id: follower.id,
            notifiable_id: notifiable.id,
            notifiable_type: notifiable.class.name,
            action: action,
            json_data: json_data,
            notified_at: Time.current,
          )
        end
        Notification.import! notifications
      end

      private

      attr_reader :notifiable, :action

      def followers
        followers = notifiable.user.followers_scoped.where(subscription_status: "all_articles").map(&:follower)
        followers += notifiable.organization.followers_scoped.where(subscription_status: "all_articles").map(&:follower) if notifiable.organization_id
        followers.uniq.compact
      end
    end
  end
end
