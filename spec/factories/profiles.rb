FactoryBot.define do
  factory :profile do
    user { association(:user, _skip_creating_profile: true) }
  end
end
