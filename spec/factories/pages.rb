FactoryBot.define do
  factory :page do
    title         { Faker::Book.title }
    body_markdown { user ? nil : Faker::Lorem.sentence }
    body_html     { user ? "<p>#{Faker::Lorem.sentence}</p>" : nil }
    slug do
      if user
        suffix = Faker::Internet.slug(glue: "-").downcase.gsub(/[^a-z0-9\-]/, "-").squeeze("-").gsub(/\A-+|-+\z/, "")
        "#{user.username}/embed/#{suffix.presence || 'embed-widget'}"
      else
        Faker::Internet.slug
      end
    end
    description   { Faker::Lorem.sentence }
    template      { user ? "embed_html" : "contained" }

    # Validations prevent creating pages with reserved words, but empty test
    # database populated without these objects, this allows a bypass to create
    # those pages for specific test scenarios.
    trait :without_validations do
      to_create { |instance| instance.save(validate: false) }
    end

    trait :for_organization do
      organization
    end
  end
end
