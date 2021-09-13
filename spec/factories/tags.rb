FactoryBot.define do
  sequence(:name) { |n| "tag你好#{n}" }

  factory :tag do
    name { generate :name }
    supported { true }
  end
end
