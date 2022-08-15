FactoryBot.define do
  factory :context_notification do
    action { "Published" }
    association :context, factory: :article
  end
end
