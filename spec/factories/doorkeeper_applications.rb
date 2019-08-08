FactoryBot.define do
  factory :application, class: "Doorkeeper::Application" do
    sequence(:name)         { |n| "Project #{n}" }
    sequence(:redirect_uri) { |n| "https://example#{n}.com" }
    secret                  { SecureRandom.hex(8) }
    uid                     { SecureRandom.hex(8) }
  end
end
