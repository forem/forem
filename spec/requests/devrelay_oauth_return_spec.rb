require "rails_helper"

RSpec.describe "DevRelay OAuth callbacks and allowlisted return-to-Core", type: :request do
  include OmniauthHelpers

  before do
    allow(ForemStatsClient).to receive(:increment)
    allow(Honeybadger).to receive(:notify)
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    omniauth_mock_mlh_payload
  end

  after { omniauth_reset_mock }

  # The Rails integration test cookie jar does not reliably replay the Redis
  # session id between separate requests in this flow, so thread the session
  # cookie explicitly: capture Set-Cookie after each response and resend it.
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

  # Mirror the real deployment contract: when the local Core-as-MyMLH gate is
  # active, the strategy arrives with credentials already stripped (the gem's
  # persist_credentials: false), so the mock must produce the identical shape.
  def mlh_sign_in(payload, params = {})
    if ENV["MLH_OAUTH_BASE_URL"].present?
      payload.credentials = OmniAuth::AuthHash.new(
        token: "", refresh_token: nil, secret: "", expires: false
      )
    end
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

  around(:each, :local_mymlh_scrub) do |example|
    old_oauth = ENV["MLH_OAUTH_BASE_URL"]
    old_api = ENV["MLH_API_BASE_URL"]
    ENV["MLH_OAUTH_BASE_URL"] = "https://auth.mlh.test"
    ENV["MLH_API_BASE_URL"] = "https://api.mlh.test"
    example.run
  ensure
    ENV["MLH_OAUTH_BASE_URL"] = old_oauth
    ENV["MLH_API_BASE_URL"] = old_api
  end

  # Case 1: a fresh provider email creates a confirmed account and attaches
  # the mlh identity under uid = Core user id.
  it "creates a confirmed account for a new email, attaching the mlh identity",
     :local_mymlh_scrub do
    payload = mlh_payload(uid: "910001", email: "newbie.devrelay@mlh.test")

    expect do
      mlh_sign_in(payload)
      expect(response).to have_http_status(:redirect)
    end.to change(User, :count).by(1)

    user = User.find_by!(email: "newbie.devrelay@mlh.test")
    expect(user).to be_confirmed
    identity = user.identities.find_by(provider: "mlh")
    expect(identity.uid).to eq("910001")

    # Local Core-as-MyMLH mode: no bearer material survives the callback.
    expect(identity.token).to be_blank
    expect(identity.auth_data_dump.credentials.refresh_token).to be_nil
    expect(identity.auth_data_dump.credentials.token).to be_blank
  end


  # Case 2: an eligible exact-email match links the identity to that user.
  it "links an unclaimed identity via exact verified email without creating a user" do
    existing = create(:user)
    payload = mlh_payload(uid: "910002", email: existing.email)

    expect do
      mlh_sign_in(payload)
    end.not_to change(User, :count)

    expect(existing.reload.identities.find_by(provider: "mlh").uid).to eq("910002")
  end

  around(:each, :real_mymlh_persistence) do |example|
    old_oauth = ENV.delete("MLH_OAUTH_BASE_URL")
    old_api = ENV.delete("MLH_API_BASE_URL")
    example.run
  ensure
    ENV["MLH_OAUTH_BASE_URL"] = old_oauth
    ENV["MLH_API_BASE_URL"] = old_api
  end

  # Case 3: an already-linked identity refreshes in place for the same user.
  # Runs without the local scrub env so production token persistence stays covered.
  it "refreshes the existing identity when the same user re-authenticates",
     :real_mymlh_persistence do
    user = create(:user)
    create(:identity, user: user, provider: "mlh", uid: "910003")
    payload = mlh_payload(uid: "910003", email: user.email, token: "fresh-token")

    expect do
      mlh_sign_in(payload)
    end.not_to change(Identity, :count)

    expect(Identity.find_by(provider: "mlh", uid: "910003").token).to eq("fresh-token")
    expect(signed_in_user_id).to eq(user.id)
  end

  # Case 4: an active DIFFERENT session + unclaimed uid resolving to another
  # account renders the confirmation interstitial; nothing mutates until
  # Confirm, and Cancel leaves zero changes.
  describe "account switch confirmation" do
    let(:session_user) { create(:user) }
    let(:target) { create(:user) }
    let(:payload) { mlh_payload(uid: "910004", email: target.email) }

    before { sign_in session_user }

    it "renders the interstitial without any mutation, then switches on Confirm" do
      mlh_sign_in(payload)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.username)
      expect(response.body).to include("/users/auth/account_switch/confirm")

      # No mutation happened while asking.
      expect(Identity.where(provider: "mlh", uid: "910004")).to be_none

      post_with_session "/users/auth/account_switch/confirm"

      identity = Identity.find_by!(provider: "mlh", uid: "910004")
      expect(identity.user_id).to eq(target.id)
      # The old session was dropped: warden now holds the resolved account.
      expect(signed_in_user_id).to eq(target.id)
    end

    it "leaves everything untouched on Cancel" do
      mlh_sign_in(payload)
      expect(response.body).to include("/users/auth/account_switch/cancel")

      post_with_session "/users/auth/account_switch/cancel"

      expect(Identity.where(provider: "mlh", uid: "910004")).to be_none
      expect(signed_in_user_id).to eq(session_user.id)
      expect(session["pending_account_switch"]).to be_nil
    end
  end

  # Case 5: a suspended resolution target fails closed — no interstitial,
  # the identity attaches to NOBODY, and the active session is preserved.
  it "fails closed with zero identity mutation for a suspended resolution target" do
    suspended = create(:user)
    suspended.add_role(:suspended)
    active = create(:user)
    sign_in active

    expect do
      mlh_sign_in(mlh_payload(uid: "910005", email: suspended.email))
    end.not_to change(Identity, :count)

    expect(response).to redirect_to(root_path) # generic moderation failure
    expect(suspended.reload.identities.where(provider: "mlh")).to be_none
    expect(active.reload.identities.where(provider: "mlh")).to be_none
    expect(signed_in_user_id).to eq(active.id) # active session preserved
  end

  # Case 6: an onboarding-incomplete account still receives the allowlisted
  # return-to-Core redirect (controller-level proof of the JS exemption).
  describe "allowlisted return-to-Core redirect" do
    around do |example|
      original = ENV["FOREM_EXTERNAL_RETURN_ORIGINS"]
      ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = "https://auth.mlh.test/web/auth/oauth/forem_returns"
      example.run
    ensure
      ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = original
    end

    it "redirects an onboarding-incomplete user to Core with the continuation verbatim" do
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

    it "falls back to normal post-auth routing when the return is not allowlisted" do
      original = ENV["FOREM_EXTERNAL_RETURN_ORIGINS"]
      ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = ""
      begin
        user = create(:user)
        mlh_sign_in(mlh_payload(uid: "910007", email: user.email), continuation: "cont-token_2")
        expect(response.redirect_url).not_to include("auth.mlh.test")
      ensure
        ENV["FOREM_EXTERNAL_RETURN_ORIGINS"] = original
      end
    end
  end
end
