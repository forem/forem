FactoryBot.define do
  factory :poll_vote do
    user
    poll
    poll_option
    session_start { 0 }
  end
end
