FactoryBot.define do
  factory :collection do
    slug { "word-#{rand(10_000)}" }
  end
end
