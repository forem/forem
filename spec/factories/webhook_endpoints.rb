FactoryBot.define do
  factory :webhook_endpoint, class: "Webhook::Endpoint" do
    target_url { Faker::Internet.url(scheme: "https") }
    events { Webhook::Event::EVENT_TYPES }
    user
    source { "stackbit" }
  end
end
