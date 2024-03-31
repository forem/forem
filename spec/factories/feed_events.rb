FactoryBot.define do
  factory :feed_event do
    sequence(:article_position)
    category { :impression }
    context_type { FeedEvent::CONTEXT_TYPE_HOME }
    article
    user
  end
end
