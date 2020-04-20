require "rails_helper"

RSpec.describe "Authenticating with Twitter" do
  let(:sign_in_link) { "Sign In With Twitter" }

  before { mock_twitter }

  context "when a user is new" do
    context "when using valid credentials" do
      it "logs in and redirects to the onboarding" do
        visit root_path
        click_link sign_in_link

        expect(page).to have_current_path("/onboarding?referrer=none")
        expect(page.html).to include("onboarding-container")
      end
    end

    context "when using invalid credentials" do
      before do
        mock_auth_with_invalid_credentials(:twitter)

        allow(DatadogStatsClient).to receive(:increment)
      end

      after do
        OmniAuth.config.on_failure = OmniauthMacros.const_get("OMNIAUTH_DEFAULT_FAILURE_HANDLER")
      end

      it "does not log in" do
        visit root_path
        click_link sign_in_link

        expect(page).to have_current_path("/users/sign_in")
        expect(page).to have_link("Sign In/Up")
        expect(page).to have_link("Via Twitter")
        expect(page).to have_link("All about #{ApplicationConfig['COMMUNITY_NAME']}")
      end

      it "notifies Datadog about a callback error" do
        error = OmniAuth::Strategies::OAuth2::CallbackError.new(
          "Callback error", "Error reason", "https://example.com/error"
        )

        setup_omniauth_error(error)

        visit root_path
        click_link sign_in_link

        args = omniauth_failure_args(error, "twitter", "{}")
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
        click_link sign_in_link

        args = omniauth_failure_args(error, "twitter", "{}")
        expect(DatadogStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog even with no OmniAuth error present" do
        error = nil
        setup_omniauth_error(error)

        visit root_path
        click_link sign_in_link

        args = omniauth_failure_args(error, "twitter", "{}")
        expect(DatadogStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end
    end
  end

  context "when a user already exists" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
    let(:user) { create(:user, :with_identity, identities: [:twitter]) }

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
