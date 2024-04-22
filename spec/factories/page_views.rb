FactoryBot.define do
  factory :page_view do
    user
    article
    referrer { Faker::Internet.url }
  end

  factory :page_page_view, class: "PageView" do
    user
    page
    referrer { Faker::Internet.url }
  end
end
