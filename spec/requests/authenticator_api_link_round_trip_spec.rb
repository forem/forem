require "rails_helper"

RSpec.describe "API-linked identity round-trips through OAuth login" do
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }

  it "reuses an API-pre-created Identity row on first OAuth login (no duplicate user, no duplicate identity)" do
    allow(Settings::Authentication).to receive_messages(providers: Authentication::Providers.available,
                                                        acceptable_domain?: true)

    target = create(:user)
    secret = create(:api_secret, user: create(:user, :super_admin)).secret

    # Pre-link via API
    post "/api/admin/users/#{target.id}/identities",
         params: { provider: "mlh", uid: "core-roundtrip", username: "rt_user" },
         headers: { "api-key" => secret, "Accept" => "application/vnd.forem.api-v1+json" }
    expect(response).to have_http_status(:created)
    pre_existing_id = Identity.find_by!(provider: "mlh", uid: "core-roundtrip").id

    # Build the omniauth payload that MyMLH would send.
    auth_payload = OmniAuth::AuthHash.new(
      provider: "mlh",
      uid: "core-roundtrip",
      info: OmniAuth::AuthHash::InfoHash.new(
        email: target.email, name: target.name, nickname: "rt_user",
      ),
      credentials: OmniAuth::AuthHash.new(token: "tok", secret: "sec"),
      extra: OmniAuth::AuthHash.new(raw_info: OmniAuth::AuthHash.new(created_at: Time.current.iso8601)),
    )

    expect do
      authed = Authentication::Authenticator.call(auth_payload, current_user: nil)
      expect(authed.id).to eq(target.id)
    end.not_to change(User, :count)

    expect(Identity.where(provider: "mlh", uid: "core-roundtrip").count).to eq(1)
    expect(Identity.find(pre_existing_id).user_id).to eq(target.id)
    expect(Identity.find(pre_existing_id).token).to eq("tok")
  end
end
