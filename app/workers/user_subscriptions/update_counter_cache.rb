module UserSubscriptions
  class UpdateCounterCache
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 10

    def perform
      user_subscriptions = UserSubscription
        .where(created_at: 2.hours.ago..Time.current)
        .select(:author_id, :user_subscription_sourceable_id)
        .pluck(:author_id, :user_subscription_sourceable_id)

      author_ids = Set.new(user_subscriptions.map(&:first))
      article_ids = Set.new(user_subscriptions.map(&:last))

      author_ids.each do |id|
        author = User.find(id)
        author.subscribed_to_user_subscriptions_count = user.subscribers.count
        author.save
      end

      article_ids.each do |id|
        article = Article.find(id)
        article.user_subscriptions_count = artice.user_subscriptions.count
        article.save
      end
    end
  end
end
