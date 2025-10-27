FactoryBot.define do
  factory :subforem do
    sequence(:domain) { |n| "subforem-#{n}.test" }
  end
end