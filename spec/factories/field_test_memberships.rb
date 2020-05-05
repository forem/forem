FactoryBot.define do
  factory :field_test_membership, class: "FieldTest::Membership" do
    converted         { false }
    experiment        { :user_home_feed }
    participant_type  { "User" }
    variant           { "base" }
  end
end
