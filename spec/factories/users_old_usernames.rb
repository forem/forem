FactoryBot.define do
  factory :users_old_username do
    user
    username { Faker::Internet.username(specifier: 2..20, separators: %w[_]) }
  end
end
