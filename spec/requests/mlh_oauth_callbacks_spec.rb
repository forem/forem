require "rails_helper"

# MLH-specific behaviour only. Provider-neutral interstitial coverage lives in
# spec/requests/account_switch_interstitial_spec.rb.
RSpec.describe "MLH OAuth callbacks" do
  include OmniauthHelpers
  include OmniauthSessionHelpers

  before do
    allow(ForemStatsClient).to receive(:increment)
    allow(Honeybadger).to receive(:notify)
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    omniauth_mock_mlh_payload
  end

  after { omniauth_reset_mock }

  def mlh_payload(uid:, email:, token: "tok-#{uid}")
    OmniAuth::AuthHash.new(
      provider: "mlh",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: "MLH User"),
      credentials: OmniAuth::AuthHash.new(token: token, secret: "sec"),
      extra: { raw_info: { created_at: 2.years.ago.iso8601 } },
    )
  end

  describe "account switch" do
    let(:session_user) { create(:user) }
    let(:target) { create(:user) }
    let(:payload) { mlh_payload(uid: "910004", email: target.email) }

    before { sign_in session_user }

    it "does not carry MLH bearer credentials through the switch", :aggregate_failures do
      omniauth_sign_in(:mlh, payload)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("data-account-switch-confirmation")
      expect(session["pending_account_switch"].to_json).not_to include("tok-910004")

      post_with_session "/users/auth/account_switch/confirm"

      identity = Identity.find_by!(provider: "mlh", uid: "910004")
      expect(identity.user_id).to eq(target.id)
      expect(identity.token).to be_blank
      expect(identity.secret).to be_blank
      expect(signed_in_user_id).to eq(target.id)
    end
  end
end
