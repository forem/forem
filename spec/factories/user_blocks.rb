FactoryBot.define do
  factory :user_block do
    blocker { user }
    blocked { user }
    config { "default" }
  end
end
