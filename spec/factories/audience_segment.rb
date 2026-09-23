FactoryBot.define do
  factory :audience_segment do
    sequence(:name) { |n| "Segment #{n}" }
    type_of { :manual }
  end
end
