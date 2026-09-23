FactoryBot.define do
  factory :email do
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.sentence }
    status { "active" }

    trait :with_custom_footer do
      override_footer_html { true }
      custom_footer_html { "<p>Custom email footer</p>" }
    end

    trait :with_footer_suppressed do
      override_footer_html { true }
      custom_footer_html { "" }
    end
  end
end
