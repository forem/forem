require "rails_helper"

RSpec.describe "Authenticating with Apple", vcr: { cassette_name: "fastly_sloan" } do
  let(:sign_in_link) { "Continue with Apple" }

  before do
    omniauth_mock_apple_payload
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

  context "when a user is new" do
    context "when using valid credentials" do
      it "creates a new user" do
        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.to change(User, :count).by(1)
      end

      it "logs in and redirects to the onboarding" do
        visit sign_up_path
        click_on(sign_in_link, match: :first)

        expect(page).to have_current_path("/onboarding", ignore_query: true)
        expect(page.html).to include("onboarding-container")
      end

      it "remembers the user" do
        visit sign_up_path
        click_on(sign_in_link, match: :first)

        user = User.last

        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end
    end

    context "when trying to register with an already existing username" do
      it "creates a new user with a temporary username" do
        # see Authentication::Providers::Apple#new_user_data
        username = OmniAuth.config.mock_auth[:apple].info.first_name.downcase
        user = create(:user, username: username)

        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.to change(User, :count).by(1)

        expect(page).to have_current_path("/onboarding", ignore_query: true)
        expect(User.last.username).to include(user.username)
      end
    end

    context "when using invalid credentials" do
      let(:params) do
        '{"callback_url"=>"http://localhost:3000/users/auth/apple/callback", "state"=>"navbar_basic"}'
      end

      before do
        omniauth_setup_invalid_credentials(:apple)

        allow(ForemStatsClient).to receive(:increment)
      end

      after do
        OmniAuth.config.on_failure = OmniauthHelpers.const_get("OMNIAUTH_DEFAULT_FAILURE_HANDLER")
      end

      it "does not create a new user" do
        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.not_to change(User, :count)
      end

      it "notifies Datadog about a callback error" do
        error = OmniAuth::Strategies::OAuth2::CallbackError.new(
          "Callback error", "Error reason", "https://example.com/error"
        )

        omniauth_setup_authentication_error(error)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "apple", "{}")
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog about an OAuth unauthorized error" do
        request = double
        allow(request).to receive(:code).and_return(401)
        allow(request).to receive(:message).and_return("unauthorized")
        error = OAuth::Unauthorized.new(request)
        omniauth_setup_authentication_error(error)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "apple", "{}")
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog even with no OmniAuth error present" do
        error = nil
        omniauth_setup_authentication_error(error)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "apple", "{}")
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end
    end

    context "when a validation failure occurrs" do
      before do
        # A User is invalid if their name is more than 100 chars long
        OmniAuth.config.mock_auth[:apple].info.first_name = "X" * 101
      end

      it "does not create a new user" do
        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.not_to change(User, :count)
      end

      it "redirects to the registration page" do
        visit sign_up_path
        click_on(sign_in_link, match: :first)

        expect(page).to have_current_path("/users/sign_up")
      end

      it "logs errors" do
        allow(Honeybadger).to receive(:notify)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        expect(Honeybadger).to have_received(:notify).once
      end
    end
  end

  context "when a user already exists" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:apple] }
    let(:user) { create(:user, :with_identity, identities: [:apple]) }

    before do
      # Apple sends nil as `first_name` and `last_name` for an existing user
      auth_payload.info.first_name = auth_payload.info.last_name = nil
      auth_payload.info.email = user.email
    end

    after do
      sign_out user
    end

    context "when using valid credentials" do
      it "logs in" do
        visit sign_up_path
        click_on(sign_in_link, match: :first)

        expect(page).to have_current_path("/?signin=true")
      end
    end

    context "when already signed in" do
      it "redirects to the feed" do
        sign_in user
        visit user_apple_omniauth_authorize_path

        expect(page).to have_current_path("/?signin=true")
      end
    end
  end
end
