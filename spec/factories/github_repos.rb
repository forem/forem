FactoryBot.define do
  factory :github_repo do
    user
    name               { Faker::Book.title }
    url                { Faker::Internet.url }
    description        { Faker::Book.title }
    language           { Faker::Book.title }
    bytes_size         { rand(100000) }
    watchers_count     { rand(100000) }
    github_id_code     { rand(100000) }
    stargazers_count   { rand(100000) }
    featured true
    fork false
  end
end
