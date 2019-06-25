FactoryBot.define do
  factory :page_view do
    user
    article
    referrer { Faker::Internet.url }
  end
end
