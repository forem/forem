FactoryBot.define do
  factory :mention do
    user
    mentionable_id     { rand(1000) }
    mentionable_type   { "Comment" }
  end
end
