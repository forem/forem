require "rails_helper"

RSpec.describe "OmniAuth Callbacks Failure" do
  include OmniauthHelpers

  before do
    allow(ForemStatsClient).to receive(:increment)
    allow(Rails.error).to receive(:report)
  end

  after do
    omniauth_reset_mock
    OmniAuth.config.on_failure = OmniauthHelpers::OMNIAUTH_DEFAULT_FAILURE_HANDLER
  end

  it "does not notify Honeybadger on nonce_mismatch" do
    error = OmniAuth::Strategies::OAuth2::CallbackError.new(:csrf_detected, "nonce_mismatch | nonce mismatch")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Rails.error).not_to have_received(:report)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on csrf_detected" do
    error = OmniAuth::Strategies::OAuth2::CallbackError.new(:csrf_detected, "csrf_detected | CSRF Detected")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Rails.error).not_to have_received(:report)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "notifies Honeybadger and Datadog on an unexpected CallbackError", :aggregate_failures do
    params = '{"callback_url"=>"http://localhost:3000/users/auth/apple/callback", "state"=>"navbar_basic"}'
    error = OmniAuth::Strategies::OAuth2::CallbackError.new(:access_denied, "user denied access", "https://example.com")
    omniauth_setup_authentication_error(error, params)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Rails.error).to have_received(:report).with(error)
    args = omniauth_failure_args(error, "apple", params)
    expect(ForemStatsClient).to have_received(:increment).with("omniauth.failure", *args)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on OAuth2::Error" do
    # Simulating the OAuth2 gem failing during access token fetching natively
    error = OAuth2::Error.new(Struct.new(:status, :parsed, :body).new(400, { "error" => "invalid_grant" }, ""))
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Rails.error).not_to have_received(:report)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger and notifies Datadog on OAuth::Unauthorized", :aggregate_failures do
    response_struct = Struct.new(:code, :message).new(401, "Unauthorized")
    error = OAuth::Unauthorized.new(response_struct)
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:twitter)

    post "/users/auth/twitter"
    follow_redirect!

    expect(Rails.error).not_to have_received(:report)
    args = omniauth_failure_args(error, "twitter", "{}")
    expect(ForemStatsClient).to have_received(:increment).with("omniauth.failure", *args)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "notifies Datadog even with no OmniAuth error present", :aggregate_failures do
    omniauth_setup_authentication_error(nil)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Rails.error).not_to have_received(:report)
    args = omniauth_failure_args(nil, "apple", "{}")
    expect(ForemStatsClient).to have_received(:increment).with("omniauth.failure", *args)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on OmniAuth::NoSessionError" do
    error = OmniAuth::NoSessionError.new("Session Expired")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:twitter)

    post "/users/auth/twitter"
    follow_redirect!

    expect(Rails.error).not_to have_received(:report)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on StandardError with 'access_token was nil'" do
    error = StandardError.new("access_token was nil when checking expiration")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Rails.error).not_to have_received(:report)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "notifies Honeybadger on generic standard errors" do
    error = StandardError.new("something went wrong")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Rails.error).to have_received(:report).with(error)
    expect(response).to redirect_to(new_user_session_url)
  end
end
