FactoryBot.define do
  factory :notification do
    association :user, factory: :user, strategy: :create
    association :organization, factory: :organization, strategy: :create
    notifiable { create(:article) }
  end
end
