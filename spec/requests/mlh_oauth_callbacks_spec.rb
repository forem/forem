require "rails_helper"

# MLH-specific behaviour only. Provider-neutral interstitial coverage lives in
# spec/requests/account_switch_interstitial_spec.rb. The "Core return" section
# is temporary; see Authentication::MlhCoreBridge for the removal checklist.
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

  describe "Core return (temporary bridge)" do
    around do |example|
      original_enabled = ENV.fetch("FOREM_EXTERNAL_RETURN_ENABLED", nil)
      original_url = ENV.fetch("FOREM_EXTERNAL_RETURN_URL", nil)
      ENV["FOREM_EXTERNAL_RETURN_ENABLED"] = "true"
      ENV["FOREM_EXTERNAL_RETURN_URL"] = "https://www.mlh.test/oauth/dev"
      example.run
    ensure
      ENV["FOREM_EXTERNAL_RETURN_URL"] = original_url
      ENV["FOREM_EXTERNAL_RETURN_ENABLED"] = original_enabled
    end

    it "returns a directly signed-in user to Core, even before onboarding", :aggregate_failures do
      incomplete = create(:user, saw_onboarding: false, checked_code_of_conduct: false,
                                 checked_terms_and_conditions: false)

      omniauth_sign_in(:mlh, mlh_payload(uid: "910006", email: incomplete.email),
                       params: { continuation: "cont-token_1" })

      expect(response).to redirect_to("https://www.mlh.test/oauth/dev?continuation=cont-token_1")
      expect(signed_in_user_id).to eq(incomplete.id)
    end

    it "carries the continuation through the interstitial and returns the switched user", :aggregate_failures do
      sign_in create(:user)
      target = create(:user)
      omniauth_sign_in(:mlh, mlh_payload(uid: "910008", email: target.email), params: { continuation: "cont-token_1" })

      expect(session["pending_account_switch"]["return_context"]).to eq("continuation" => "cont-token_1")

      post_with_session "/users/auth/account_switch/confirm"

      expect(response).to redirect_to("https://www.mlh.test/oauth/dev?continuation=cont-token_1")
      expect(signed_in_user_id).to eq(target.id)
    end

    it "ignores a malformed continuation" do
      user = create(:user)

      omniauth_sign_in(:mlh, mlh_payload(uid: "910009", email: user.email), params: { continuation: "bad token&x=1" })

      expect(response.location).to start_with("http://www.example.com/")
    end

    it "filters the continuation out of failure telemetry" do
      omniauth_setup_invalid_credentials(:mlh)

      get_with_session "/users/auth/mlh", params: { continuation: "cont-token_1" }
      get_with_session "/users/auth/mlh/callback"

      expect(ForemStatsClient).to have_received(:increment).with(
        "omniauth.failure", tags: array_including('params:{"continuation"=>"[FILTERED]"}')
      )
    end

    it "keeps normal onboarding when the bridge is disabled despite a configured URL", :aggregate_failures do
      ENV.delete("FOREM_EXTERNAL_RETURN_ENABLED")
      incomplete = create(:user, saw_onboarding: false, checked_code_of_conduct: false,
                                 checked_terms_and_conditions: false)

      omniauth_sign_in(:mlh, mlh_payload(uid: "910007", email: incomplete.email),
                       params: { continuation: "cont-token_1" })

      expect(URI.parse(response.location).path).to eq("/onboarding")
      expect(signed_in_user_id).to eq(incomplete.id)
    end
  end
end
