FactoryBot.define do
  sequence(:old_slug) { |n| "/old-slug-#{n}" }
  sequence(:new_slug) { |n| "/new-slug-#{n}" }

  factory :page_redirect do
    old_slug { generate :old_slug }
    new_slug { generate :new_slug }
  end
end
