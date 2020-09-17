FactoryBot.define do
  factory :note do
    association :noteable, factory: :user
    content { Faker::Book.title }
    reason { "misc_note" }
  end
end
