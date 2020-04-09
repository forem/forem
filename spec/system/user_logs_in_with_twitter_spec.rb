require "rails_helper"

global_failure_handler = OmniAuth.config.on_failure

def user_grants_authorization_on_twitter(twitter_callback_hash)
  OmniAuth.config.add_mock(:twitter, twitter_callback_hash)
end

def user_does_not_grant_authorization_on_twitter
  OmniAuth.config.mock_auth[:twitter] = :invalid_credentials
end

def setup_omniauth_error(error)
  # this hack is needed due to a limitation in how OmniAuth handles
  # failures in mocked/testing environments,
  # see <https://github.com/omniauth/omniauth/issues/654#issuecomment-610851884>
  # for more details
  global_failure_handler = OmniAuth.config.on_failure

  local_failure_handler = lambda do |env|
    env["omniauth.error"] = error
    env
  end
  # here we compose the two handlers into a single function,
  # the result will be global_failure_handler(local_failure_handler(env))
  failure_handler = local_failure_handler >> global_failure_handler

  OmniAuth.config.on_failure = failure_handler
end

def get_failure_args(error)
  class_name = error.present? ? error.class.name : ""

  [
    tags: [
      "class:#{class_name}",
      "message:#{error&.message}",
      "reason:#{error.try(:error_reason)}",
      "type:#{error.try(:error)}",
      "uri:#{error.try(:error_uri)}",
      "provider:twitter",
      "origin:",
      "params:{}",
    ],
  ]
end

RSpec.describe "Authenticating with Twitter" do
  let(:twitter_callback_hash) do
    {
      provider: "twitter",
      uid: "111111",
      credentials: {
        token: "222222",
        secret: "333333"
      },
      extra: {
        access_token: "",
        raw_info: {
          name: "Bruce Wayne",
          created_at: "Thu Jul 4 00:00:00 +0000 2013" # This is mandatory
        }
      },
      info: {
        nickname: "batman",
        name: "Bruce Wayne",
        email: "batman@batcave.com"
      }
    }
  end

  context "when a user is new" do
    let(:twitter_link) { "Sign In With Twitter" }

    context "when using valid credentials" do
      before do
        user_grants_authorization_on_twitter(twitter_callback_hash)
      end

      it "logs in and redirects to the onboarding" do
        visit root_path
        click_link twitter_link

        expect(page).to have_current_path("/onboarding?referrer=none")
        expect(page.html).to include("onboarding-container")
      end
    end

    context "when using invalid credentials" do
      let(:callback_failure) do
        [
          "omniauth.failure",
          tags: [
            "class:",
            "message:",
            "reason:",
            "type:",
            "uri:",
            "provider:twitter",
            "origin:",
            "params:{}",
          ],
        ]
      end

      before do
        user_does_not_grant_authorization_on_twitter

        allow(DatadogStatsClient).to receive(:increment)
      end

      after do
        OmniAuth.config.on_failure = global_failure_handler
      end

      it "does not log in" do
        visit root_path
        click_link twitter_link

        expect(page).to have_current_path("/users/sign_in")
        expect(page).to have_link("Sign In/Up")
        expect(page).to have_link("Via Twitter")
        expect(page).to have_link("Via GitHub")
        expect(page).to have_link("All about #{ApplicationConfig['COMMUNITY_NAME']}")
      end

      it "notifies Datadog about a callback error" do
        error = OmniAuth::Strategies::OAuth2::CallbackError.new(
          "Callback error", "Error reason", "https://example.com/error"
        )

        setup_omniauth_error(error)

        visit root_path
        click_link twitter_link

        args = get_failure_args(error)
        expect(DatadogStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog about an OAuth unauthorized error" do
        request = double
        allow(request).to receive(:code).and_return(401)
        allow(request).to receive(:message).and_return("unauthorized")
        error = OAuth::Unauthorized.new(request)
        setup_omniauth_error(error)

        visit root_path
        click_link twitter_link

        args = get_failure_args(error)
        expect(DatadogStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog even with no OmniAuth error present" do
        error = nil
        setup_omniauth_error(error)

        visit root_path
        click_link twitter_link

        args = get_failure_args(error)
        expect(DatadogStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end
    end
  end
end
