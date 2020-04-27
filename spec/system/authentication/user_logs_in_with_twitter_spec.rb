require "rails_helper"

RSpec.describe "Authenticating with Twitter" do
  let(:sign_in_link) { "Sign In With Twitter" }

  before { mock_twitter }

  context "when a user is new" do
    context "when using valid credentials" do
      it "creates a new user" do
        expect do
          visit root_path
          click_link sign_in_link
        end.to change(User, :count).by(1)
      end

      it "logs in and redirects to the onboarding" do
        visit root_path
        click_link sign_in_link

        expect(page).to have_current_path("/onboarding?referrer=none")
        expect(page.html).to include("onboarding-container")
      end

      it "remembers the user" do
        visit root_path
        click_link sign_in_link

        user = User.last

        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end
    end

    context "when trying to register with an already existing username" do
      it "creates a new user with a temporary username" do
        username = OmniAuth.config.mock_auth[:twitter].extra.raw_info.username
        user = create(:user, username: username.delete("."))

        expect do
          visit root_path
          click_link sign_in_link
        end.to change(User, :count).by(1)

        expect(page).to have_current_path("/onboarding?referrer=none")
        expect(User.last.username).to include(user.username)
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

      it "does not create a new user" do
        expect do
          visit root_path
          click_link sign_in_link
        end.not_to change(User, :count)
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

    context "when a validation failure occurrs" do
      before do
        # A User is invalid if their name is more than 100 chars long
        OmniAuth.config.mock_auth[:twitter].extra.raw_info.name = "X" * 101
      end

      it "does not create a new user" do
        expect do
          visit root_path
          click_link sign_in_link
        end.not_to change(User, :count)
      end

      it "redirects to the registration page" do
        visit root_path
        click_link sign_in_link

        expect(page).to have_current_path("/users/sign_up")
      end

      it "logs errors" do
        allow(Rails.logger).to receive(:error)

        visit root_path
        click_link sign_in_link

        expect(Rails.logger).to have_received(:error).at_least(3).times
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
      it "logs in and redirects to the dashboard" do
        visit "/users/auth/twitter"

        expect(page).to have_current_path("/dashboard?signin=true")
      end
    end
  end
end
