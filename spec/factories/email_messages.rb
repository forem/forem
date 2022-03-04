FactoryBot.define do
  factory :email_message do
    to      { Faker::Internet.email }
    subject { Faker::Lorem.sentence }

    content { Faker::Lorem.paragraph }
  end
end
