FactoryBot.define do
  factory :scheduled_automation do
    frequency { "daily" }
    frequency_config { { "hour" => 9, "minute" => 0 } }
    action { "create_draft" }
    action_config { { "repo_name" => "forem/forem", "days_ago" => 7 } }
    service_name { "github_repo_recap" }
    state { "active" }
    enabled { true }
    next_run_at { 1.day.from_now }

    after(:build) do |scheduled_automation|
      scheduled_automation.user ||= build(:user, type_of: :community_bot)
    end

    trait :hourly do
      frequency { "hourly" }
      frequency_config { { "minute" => 30 } }
    end

    trait :weekly do
      frequency { "weekly" }
      frequency_config { { "day_of_week" => 5, "hour" => 9, "minute" => 0 } }
    end

    trait :custom_interval do
      frequency { "custom_interval" }
      frequency_config { { "interval_days" => 7, "hour" => 9, "minute" => 0 } }
    end

    trait :publish_article do
      action { "publish_article" }
    end

    trait :disabled do
      enabled { false }
    end

    trait :running do
      state { "running" }
    end

    trait :failed do
      state { "failed" }
    end

    trait :due do
      next_run_at { 10.minutes.ago }
    end
  end
end

