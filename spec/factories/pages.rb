FactoryBot.define do
  factory :page do
    title         { Faker::Book.title }
    body_markdown { Faker::Lorem.sentence }
    slug          { Faker::Internet.slug }
    description   { Faker::Lorem.sentence }
    template      { "contained" }

    # Validations prevent creating pages with reserved words, but empty test
    # database populated without these objects, this allows a bypass to create
    # those pages for specific test scenarios.
    trait :without_validations do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end
