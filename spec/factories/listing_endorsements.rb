FactoryBot.define do
  factory :listing_endorsement do
    user
    listing
    content { "#{Faker::Lorem.sentence} " }
    approved { true }
  end
end
