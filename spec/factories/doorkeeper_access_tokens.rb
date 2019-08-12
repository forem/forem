FactoryBot.define do
  factory :doorkeeper_access_token, class: "Doorkeeper::AccessToken" do
    application
  end
end
