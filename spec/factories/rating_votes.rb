FactoryBot.define do
  factory :rating_vote do
    user
    group { "experience_level" }
    rating { rand(1.0..8.0) }
    after(:build) do |vote|
      vote.article ||= create(:article, user: vote.user)
    end
  end
end
