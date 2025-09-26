FactoryBot.define do
  factory :user_query do
    name { "Test User Query" }
    description { "A test query for targeting users" }
    query { "SELECT id FROM users WHERE created_at > '2023-01-01'" }
    max_execution_time_ms { 30000 }
    active { true }
    execution_count { 0 }
    association :created_by, factory: :user

    trait :inactive do
      active { false }
    end

    trait :with_joins do
      query { "SELECT users.id FROM users JOIN profiles ON users.id = profiles.user_id WHERE profiles.bio IS NOT NULL" }
    end

    trait :with_complex_where do
      query { "SELECT id FROM users WHERE created_at > '2023-01-01' AND email IS NOT NULL AND registered = true" }
    end

    trait :with_limit do
      query { "SELECT id FROM users ORDER BY created_at DESC LIMIT 100" }
    end

    trait :executed do
      execution_count { 5 }
      last_executed_at { 1.hour.ago }
    end

    trait :long_running do
      query { "SELECT id FROM users WHERE created_at > '2020-01-01' AND articles_count > 0" }
      max_execution_time_ms { 120000 }
    end

    trait :invalid_query do
      query { "UPDATE users SET name = 'test'" }
    end

    trait :with_forbidden_keyword do
      query { "SELECT id FROM users; DELETE FROM users;" }
    end

    trait :with_suspicious_pattern do
      query { "SELECT id FROM users -- comment" }
    end
  end
end


