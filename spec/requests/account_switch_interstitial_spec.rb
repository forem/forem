require "rails_helper"

# Provider-neutral coverage for the account-switch interstitial. GitHub stands in
# for "any OmniAuth provider"; nothing here depends on a specific integration.
RSpec.describe "Account switch interstitial" do
  include OmniauthHelpers
  include OmniauthSessionHelpers
  include ActiveSupport::Testing::TimeHelpers

  before do
    allow(ForemStatsClient).to receive(:increment)
    allow(Honeybadger).to receive(:notify)
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    sign_in session_user
  end

  after { omniauth_reset_mock }

  def github_payload(uid:, email:, nickname:, token: "github-access-token")
    OmniAuth::AuthHash.new(
      provider: "github",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: "GitHub User", nickname: nickname),
      credentials: OmniAuth::AuthHash.new(token: token, secret: "sec"),
      extra: { raw_info: { name: "GitHub User", created_at: 2.years.ago.iso8601 } },
    )
  end

  let(:session_user) { create(:user) }
  let(:target) { create(:user) }
  let(:payload) { github_payload(uid: "810004", email: target.email, nickname: target.username) }

  it "renders the interstitial without mutation, then switches on confirmation", :aggregate_failures do
    omniauth_sign_in(:github, payload)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-account-switch-confirmation")
    expect(response.body).to include(target.username)
    expect(response.body).to include("/users/auth/account_switch/confirm")
    expect(Identity.where(provider: "github", uid: "810004")).to be_none
    expect(signed_in_user_id).to eq(session_user.id)

    post_with_session "/users/auth/account_switch/confirm"

    identity = Identity.find_by!(provider: "github", uid: "810004")
    expect(identity.user_id).to eq(target.id)
    expect(signed_in_user_id).to eq(target.id)
    expect(session["pending_account_switch"]).to be_nil
  end

  it "keeps provider credentials encrypted in the pending session and restores them on confirm", :aggregate_failures do
    omniauth_sign_in(:github, payload)

    expect(session["pending_account_switch"].to_json).not_to include("github-access-token")

    post_with_session "/users/auth/account_switch/confirm"

    expect(Identity.find_by!(provider: "github", uid: "810004").token).to eq("github-access-token")
  end

  it "rejects a target whose email changes before confirmation", :aggregate_failures do
    omniauth_sign_in(:github, payload)
    # Model callbacks stage reconfirmation; simulate a completed email change.
    target.update_columns(email: "changed@example.com")

    expect { post_with_session "/users/auth/account_switch/confirm" }.not_to change(Identity, :count)
    expect(signed_in_user_id).to eq(session_user.id)
  end

  it "rejects an identity reassigned after staging", :aggregate_failures do
    omniauth_sign_in(:github, payload)
    other = create(:user)
    identity = create(:identity, provider: "github", uid: "810004", user: other, token: "original")

    post_with_session "/users/auth/account_switch/confirm"

    expect(identity.reload.token).to eq("original")
    expect(signed_in_user_id).to eq(session_user.id)
  end

  it "rejects a target that becomes unconfirmed", :aggregate_failures do
    omniauth_sign_in(:github, payload)
    target.update_columns(confirmed_at: nil)

    expect { post_with_session "/users/auth/account_switch/confirm" }.not_to change(Identity, :count)
    expect(signed_in_user_id).to eq(session_user.id)
  end

  it "handles a newly blocked email domain without ending the current session", :aggregate_failures do
    omniauth_sign_in(:github, payload)
    allow(Settings::Authentication).to receive(:acceptable_domain?).and_return(false)

    post_with_session "/users/auth/account_switch/confirm"

    expect(response).to redirect_to(root_path)
    expect(signed_in_user_id).to eq(session_user.id)
    expect(Identity.where(provider: "github", uid: "810004")).to be_none
  end

  it "rejects an expired staged payload", :aggregate_failures do
    omniauth_sign_in(:github, payload)
    travel_to 16.minutes.from_now do
      post_with_session "/users/auth/account_switch/confirm"
    end

    expect(response).to redirect_to(root_path)
    expect(signed_in_user_id).to eq(session_user.id)
    expect(Identity.where(provider: "github", uid: "810004")).to be_none
  end

  it "reports a persistence failure during confirmation without switching sessions", :aggregate_failures do
    omniauth_sign_in(:github, payload)
    allow(Authentication::Authenticator).to receive(:call).and_wrap_original do |original, *args, **kwargs|
      raise ActiveRecord::RecordInvalid, User.new if kwargs[:expected_user]

      original.call(*args, **kwargs)
    end

    post_with_session "/users/auth/account_switch/confirm"

    expect(response).to redirect_to(new_user_registration_url)
    expect(flash[:alert]).to be_present
    expect(signed_in_user_id).to eq(session_user.id)
    expect(Identity.where(provider: "github", uid: "810004")).to be_none
  end

  it "redirects to the root when nothing is pending" do
    post_with_session "/users/auth/account_switch/confirm"

    expect(response).to redirect_to(root_path)
    expect(signed_in_user_id).to eq(session_user.id)
  end

  it "preserves session and identity state when canceled", :aggregate_failures do
    omniauth_sign_in(:github, payload)
    expect(response.body).to include("/users/auth/account_switch/cancel")

    post_with_session "/users/auth/account_switch/cancel"

    expect(Identity.where(provider: "github", uid: "810004")).to be_none
    expect(signed_in_user_id).to eq(session_user.id)
    expect(session["pending_account_switch"]).to be_nil
  end

  it "fails closed with zero identity mutation for a suspended resolution target", :aggregate_failures do
    suspended = create(:user)
    suspended.add_role(:suspended)

    expect do
      omniauth_sign_in(:github, github_payload(uid: "810005", email: suspended.email, nickname: suspended.username))
    end.not_to change(Identity, :count)

    expect(response).to redirect_to(root_path)
    expect(signed_in_user_id).to eq(session_user.id)
  end
end
