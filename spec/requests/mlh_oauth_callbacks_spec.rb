require "rails_helper"

RSpec.describe "MLH OAuth callbacks", type: :request do
  include OmniauthHelpers

  before do
    allow(ForemStatsClient).to receive(:increment)
    allow(Honeybadger).to receive(:notify)
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    omniauth_mock_mlh_payload
  end

  after { omniauth_reset_mock }

  # Redis-backed request specs need the session cookie forwarded explicitly.
  def follow_session_cookie
    cookie = response.headers["Set-Cookie"].to_s.split("\n").map { |c| c.split(";").first }.join("; ")
    @session_cookie = cookie.presence if cookie.present?
  end

  def get_with_session(path, params = {})
    get path, params: params, headers: (@session_cookie ? { "Cookie" => @session_cookie } : {})
    follow_session_cookie
  end

  def post_with_session(path)
    post path, headers: (@session_cookie ? { "Cookie" => @session_cookie } : {})
    follow_session_cookie
  end

  def mlh_sign_in(payload, params = {})
    OmniAuth.config.mock_auth[:mlh] = payload
    get_with_session "/users/auth/mlh", params
    get_with_session "/users/auth/mlh/callback"
  end

  def signed_in_user_id
    session["warden.user.user.key"].to_a.flatten.map(&:to_s).first&.to_i
  end

  def mlh_payload(uid:, email:, token: "tok-#{uid}")
    OmniAuth::AuthHash.new(
      provider: "mlh",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: "MLH User"),
      credentials: OmniAuth::AuthHash.new(token: token, secret: "sec"),
      extra: { raw_info: { created_at: 2.years.ago.iso8601 } },
    )
  end

  describe "account switch confirmation" do
    let(:session_user) { create(:user) }
    let(:target) { create(:user) }
    let(:payload) { mlh_payload(uid: "910004", email: target.email) }

    before { sign_in session_user }

    it "renders the interstitial without mutation, then switches on confirmation", :aggregate_failures do
      mlh_sign_in(payload)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.username)
      expect(response.body).to include("/users/auth/account_switch/confirm")

      expect(Identity.where(provider: "mlh", uid: "910004")).to be_none

      post_with_session "/users/auth/account_switch/confirm"

      identity = Identity.find_by!(provider: "mlh", uid: "910004")
      expect(identity.user_id).to eq(target.id)
      expect(identity.token).to be_blank
      expect(identity.secret).to be_blank
      expect(signed_in_user_id).to eq(target.id)
    end

    it "preserves session and identity state when canceled" do
      mlh_sign_in(payload)
      expect(response.body).to include("/users/auth/account_switch/cancel")

      post_with_session "/users/auth/account_switch/cancel"

      expect(Identity.where(provider: "mlh", uid: "910004")).to be_none
      expect(signed_in_user_id).to eq(session_user.id)
      expect(session["pending_account_switch"]).to be_nil
    end
  end

  it "fails closed with zero identity mutation for a suspended resolution target" do
    suspended = create(:user)
    suspended.add_role(:suspended)
    active = create(:user)
    sign_in active

    expect do
      mlh_sign_in(mlh_payload(uid: "910005", email: suspended.email))
    end.not_to change(Identity, :count)

    expect(response).to redirect_to(root_path)
    expect(signed_in_user_id).to eq(active.id)
  end

  describe "allowlisted external return" do
    around do |example|
      original = ENV["FOREM_EXTERNAL_RETURN_ORIGINS"]
      ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = "https://auth.mlh.test/web/auth/oauth/forem_returns"
      example.run
    ensure
      ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = original
    end

    it "redirects an onboarding-incomplete user to the allowlisted return" do
      incomplete = create(
        :user,
        saw_onboarding: false,
        checked_code_of_conduct: false,
        checked_terms_and_conditions: false,
      )

      mlh_sign_in(mlh_payload(uid: "910006", email: incomplete.email), continuation: "cont-token_1")

      expect(response).to redirect_to(
        "https://auth.mlh.test/web/auth/oauth/forem_returns?continuation=cont-token_1",
      )
    end
  end
end
