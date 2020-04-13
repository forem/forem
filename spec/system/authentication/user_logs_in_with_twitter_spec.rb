require "rails_helper"

global_failure_handler = OmniAuth.config.on_failure

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
  before { mock_twitter }

  context "when a user is new" do
    let(:twitter_link) { "Sign In With Twitter" }

    context "when using valid credentials" do
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
        mock_twitter_with_invalid_credentials

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

  context "when a user already exists" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
    let(:user) { create(:user, :with_identity, identities: [:twitter]) }
    let(:twitter_link) { "Sign In With Twitter" }

    before do
      auth_payload.info.email = user.email
      sign_in user
    end

    context "when using valid credentials" do
      it "logs in and redirects to the onboarding" do
        visit "/users/auth/twitter"

        expect(page).to have_current_path("/dashboard?signin=true")
      end
    end
  end
end
