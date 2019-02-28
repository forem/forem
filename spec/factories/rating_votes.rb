FactoryBot.define do
  factory :rating_vote do
    group { "experience_level" }
    rating { rand(1.0..8.0) }
  end
end
