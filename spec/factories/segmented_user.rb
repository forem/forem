FactoryBot.define do
  factory :segmented_user do
    user
    audience_segment
  end
end
