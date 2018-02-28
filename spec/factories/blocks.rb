FactoryBot.define do
  factory :block do
    input_html        { Faker::Hipster.paragraph(1) }
    input_css         { "body {color:red}" }
    input_javascript  { Faker::Hipster.paragraph(1) }
  end
end
