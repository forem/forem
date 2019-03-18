FactoryBot.define do
  factory :tag do
    name { rand(10_000).to_s }
    supported { true }
  end
end
