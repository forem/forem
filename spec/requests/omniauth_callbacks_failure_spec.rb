require 'rails_helper'

RSpec.describe "OmniAuth Callbacks Failure", type: :request do
  include OmniauthHelpers

  before do
    allow(ForemStatsClient).to receive(:increment)
    allow(Honeybadger).to receive(:notify)
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

    expect(Honeybadger).not_to have_received(:notify)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on csrf_detected" do
    error = OmniAuth::Strategies::OAuth2::CallbackError.new(:csrf_detected, "csrf_detected | CSRF Detected")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Honeybadger).not_to have_received(:notify)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "notifies Honeybadger on an unexpected CallbackError" do
    error = OmniAuth::Strategies::OAuth2::CallbackError.new(:access_denied, "user denied access")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Honeybadger).to have_received(:notify).with(error)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on OAuth2::Error" do
    # Simulating the OAuth2 gem failing during access token fetching natively
    error = OAuth2::Error.new(Struct.new(:status, :parsed, :body).new(400, { "error" => "invalid_grant" }, ""))
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Honeybadger).not_to have_received(:notify)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on OAuth::Unauthorized" do
    response_double = double("HTTPResponse", code: 401, message: "Unauthorized")
    error = Object.const_defined?("OAuth::Unauthorized") ? OAuth::Unauthorized.new(response_double) : StandardError.new("fallback")
    allow(error).to receive(:class).and_return(double(name: "OAuth::Unauthorized"))
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:twitter)

    post "/users/auth/twitter"
    follow_redirect!

    expect(Honeybadger).not_to have_received(:notify)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on OmniAuth::NoSessionError" do
    error = OmniAuth::NoSessionError.new("Session Expired")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:twitter)

    post "/users/auth/twitter"
    follow_redirect!

    expect(Honeybadger).not_to have_received(:notify)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "does not notify Honeybadger on StandardError with 'access_token was nil'" do
    error = StandardError.new("access_token was nil when checking expiration")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Honeybadger).not_to have_received(:notify)
    expect(response).to redirect_to(new_user_session_url)
  end

  it "notifies Honeybadger on generic standard errors" do
    error = StandardError.new("something went wrong")
    omniauth_setup_authentication_error(error)
    omniauth_setup_invalid_credentials(:apple)

    post "/users/auth/apple"
    follow_redirect!

    expect(Honeybadger).to have_received(:notify).with(error)
    expect(response).to redirect_to(new_user_session_url)
  end
end
