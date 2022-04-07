FactoryBot.define do
  factory :context_notification do
    action { "published" }
    association :context, factory: :article
  end
end
