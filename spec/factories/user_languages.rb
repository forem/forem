FactoryBot.define do
  factory :user_language do
    user
    language { :en }
  end
end
