FactoryBot.define do
  factory :pro_membership do
    user
    status { "active" }
    expires_at { 1.month.from_now }
  end

  trait :expired do
    status { "expired" }
    expires_at { 1.month.ago }
  end
end
