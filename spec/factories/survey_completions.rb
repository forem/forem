FactoryBot.define do
  factory :survey_completion do
    user
    survey
    completed_at { Time.current }
  end
end
