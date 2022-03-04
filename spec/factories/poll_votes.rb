FactoryBot.define do
  factory :poll_vote do
    user
    poll
    poll_option
  end
end
