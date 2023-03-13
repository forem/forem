FactoryBot.define do
  sequence(:github_id_code) { |n| n }
  sequence(:url) { |n| "#{Faker::Internet.url}#{n}" }

  factory :github_repo do
    user
    name               { Faker::Book.title }
    url                { generate(:url) }
    description        { Faker::Book.title }
    language           { Faker::Book.title }
    bytes_size         { rand(100_000) }
    watchers_count     { rand(100_000) }
    github_id_code     { generate(:github_id_code) }
    stargazers_count   { rand(100_000) }
    featured { true }
    fork { false }
  end
end
