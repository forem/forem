FactoryBot.define do
  factory :user_counter do
    user
    data { { comments_these_7_days: 0, comments_prior_7_days: 0 } }
  end
end
