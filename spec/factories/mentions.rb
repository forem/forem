FactoryBot.define do
  factory :mention do
    user
    association :mentionable, factory: :article
  end
end
