FactoryBot.define do
  factory :webhook_endpoint, class: Webhook::Endpoint do
    target_url { Faker::Internet.url(scheme: "https") }
    events { %w[article_created article_updated article_destroyed] }
    user
    source { "stackbit" }
  end
end
