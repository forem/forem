FactoryBot.define do
  factory :field_test_membership, class: "FieldTest::Membership" do
    converted         { false }
    experiment        { :follow_implicit_points }
    participant_type  { "User" }
    variant           { "base" }
  end
end
