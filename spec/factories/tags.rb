FactoryBot.define do
  sequence(:name) { |n| "tag#{n}" }

  factory :tag do
    name { generate :name }
    supported { true }
  end
end
