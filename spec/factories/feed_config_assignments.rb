FactoryBot.define do
  factory :feed_config_assignment do
    user
    feed_config
    expires_at { 60.hours.from_now }
    last_rewarded_at { Time.current }
  end
end
