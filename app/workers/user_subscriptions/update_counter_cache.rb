module UserSubscriptions
  class UpdateCounterCache
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 10

    def perform
      user_subscriptions = UserSubscription
        .where(created_at: 2.hours.ago..Time.current)
        .select(:subscriber_id, :user_subscription_sourceable_id)
        .pluck(:subscriber_id, :user_subscription_sourceable_id)

      subscriber_ids = Set.new(user_subscriptions.map(&:first))
      article_ids = Set.new(user_subscriptions.map(&:last))

      subscriber_ids.each do |id|
        subscriber = User.find(id)
        subscriber.update!(subscribed_to_user_subscriptions_count: subscriber.subscribed_to_user_subscriptions.count)
      end

      article_ids.each do |id|
        article = Article.find(id)
        article.update(user_subscriptions_count: article.user_subscriptions.count)
      end
    end
  end
end
