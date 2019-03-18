FactoryBot.define do
  factory :github_repo do
    user
    name               { Faker::Book.title }
    url                { Faker::Internet.url }
    description        { Faker::Book.title }
    language           { Faker::Book.title }
    bytes_size         { rand(100_000) }
    watchers_count     { rand(100_000) }
    github_id_code     { rand(100_000) }
    stargazers_count   { rand(100_000) }
    featured { true }
    fork { false }
  end
end
