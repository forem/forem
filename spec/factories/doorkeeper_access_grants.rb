FactoryBot.define do
  factory :doorkeeper_access_grant, class: "Doorkeeper::AccessGrant" do
    application
    expires_in { 600 }
    redirect_uri { "urn:ietf:wg:oauth:2.0:oob" }
  end
end
