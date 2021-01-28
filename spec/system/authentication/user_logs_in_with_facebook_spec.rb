require "rails_helper"

RSpec.describe "Authenticating with Facebook" do
  let(:sign_in_link) { "Continue with Facebook" }

  before do
    omniauth_mock_facebook_payload
    allow(SiteConfig).to receive(:authentication_providers).and_return(Authentication::Providers.available)
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

    context "when using valid credentials but witholding email address" do
      before do
        OmniAuth.config.mock_auth[:facebook][:info].delete(:email)
        OmniAuth.config.mock_auth[:facebook][:extra][:raw_info].delete(:email)
      end

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
        # see Authentication::Providers::Facebook#new_user_data
        username = OmniAuth.config.mock_auth[:facebook].info.name.downcase.sub(" ", "_")
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
        '{"callback_url"=>"http://localhost:3000/users/auth/facebook/callback", "state"=>"navbar_basic"}'
      end

      before do
        omniauth_setup_invalid_credentials(:facebook)

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

      it "does not log in" do
        visit sign_up_path
        click_on(sign_in_link, match: :first)

        expect(page).to have_current_path("/users/sign_in")
        expect(page).to have_button(sign_in_link)
      end

      it "notifies Datadog about a callback error" do
        error = OmniAuth::Strategies::OAuth2::CallbackError.new(
          "Callback error", "Error reason", "https://example.com/error"
        )

        omniauth_setup_authentication_error(error, params)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "facebook", params)
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog about an OAuth unauthorized error" do
        request = double
        allow(request).to receive(:code).and_return(401)
        allow(request).to receive(:message).and_return("unauthorized")
        error = OAuth::Unauthorized.new(request)
        omniauth_setup_authentication_error(error, params)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "facebook", params)
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog even with no OmniAuth error present" do
        error = nil
        omniauth_setup_authentication_error(error, params)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "facebook", params)
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end
    end

    context "when a validation failure occurrs" do
      before do
        # A User is invalid if their name is more than 100 chars long
        OmniAuth.config.mock_auth[:facebook].info.name = "X" * 101
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
    let!(:auth_payload) { OmniAuth.config.mock_auth[:facebook] }
    let(:user) { create(:user, :with_identity, identities: [:facebook]) }

    before do
      auth_payload.info.name = user.name
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
      it "redirects to the dashboard" do
        sign_in user
        visit user_facebook_omniauth_authorize_path

        expect(page).to have_current_path("/?signin=true")
      end
    end
  end

  context "when community is in invite only mode" do
    before do
      allow(SiteConfig).to receive(:invite_only_mode).and_return(true)
    end

    it "doesn't present the authentication option" do
      visit sign_up_path(state: "new-user")
      expect(page).not_to have_text(sign_in_link)
      expect(page).to have_text("invite only")
    end
  end
end
