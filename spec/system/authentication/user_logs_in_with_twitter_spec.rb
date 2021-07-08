require "rails_helper"

RSpec.describe "Authenticating with Twitter" do
  let(:sign_in_link) { "Continue with Twitter" }

  before do
    omniauth_mock_twitter_payload
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

        expect(page).to have_current_path("/onboarding?referrer=none")
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
        username = OmniAuth.config.mock_auth[:twitter].extra.raw_info.username
        user = create(:user, username: username.delete("."))

        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.to change(User, :count).by(1)

        expect(page).to have_current_path("/onboarding?referrer=none")
        expect(User.last.username).to include(user.username)
      end
    end

    context "when using invalid credentials" do
      before do
        omniauth_setup_invalid_credentials(:twitter)

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

        omniauth_setup_authentication_error(error)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "twitter", "{}")
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

        args = omniauth_failure_args(error, "twitter", "{}")
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end

      it "notifies Datadog even with no OmniAuth error present" do
        error = nil
        omniauth_setup_authentication_error(error)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        args = omniauth_failure_args(error, "twitter", "{}")
        expect(ForemStatsClient).to have_received(:increment).with(
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
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.not_to change(User, :count)
      end

      it "redirects to the registration page" do
        visit sign_up_path
        click_on(sign_in_link, match: :first)

        expect(page).to have_current_path("/users/sign_up")
      end

      it "reports errors" do
        allow(Honeybadger).to receive(:notify)

        visit sign_up_path
        click_on(sign_in_link, match: :first)

        expect(Honeybadger).to have_received(:notify)
      end
    end
  end

  context "when a user already exists" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:twitter] }
    let(:user) { create(:user, :with_identity, identities: [:twitter]) }

    before do
      auth_payload.info.email = user.email
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
        visit user_twitter_omniauth_authorize_path

        expect(page).to have_current_path("/?signin=true")
      end

      it "renders the twitter icon on the profile" do
        sign_in user
        visit user_twitter_omniauth_authorize_path

        visit user_profile_path(user.username)

        expect(page).to have_css("svg.crayons-icon.shrink-0", text: "twitter website")
      end
    end
  end

  context "when community is in invite only mode" do
    before do
      allow(ForemInstance).to receive(:private?).and_return(true)
    end

    it "doesn't present the authentication option" do
      visit sign_up_path(state: "new-user")
      expect(page).not_to have_text(sign_in_link)
      expect(page).to have_text("invite only")
    end
  end
end
