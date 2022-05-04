FactoryBot.define do
  factory :gdpr_delete_request, class: "GDPRDeleteRequest" do
    user_id { rand(100) }
    sequence(:email) { |n| "person#{n}@example.com" }
    sequence(:username) { |n| "username#{n}" }
  end
end
