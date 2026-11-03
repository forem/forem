require "rails_helper"

RSpec.describe "Authenticating with Apple", vcr: { cassette_name: "fastly_sloan" } do
  let(:sign_in_link) { "Continue with Apple" }

  before do
    omniauth_mock_apple_payload
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

  context "when a user is new" do
    context "when using valid credentials" do
      it "creates and remembers a new user, logs in, and redirects to the onboarding", :aggregate_failures do
        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.to change(User, :count).by(1)

        expect(page).to have_current_path("/onboarding", ignore_query: true)
        expect(page.html).to include("onboarding-container")

        user = User.last

        expect(user.remember_token).to be_present
        expect(user.remember_created_at).to be_present
      end
    end

    context "when trying to register with an already existing username" do
      it "creates a new user with a temporary username" do
        # see Authentication::Providers::Apple#new_user_data
        username = OmniAuth.config.mock_auth[:apple].info.first_name.downcase
        user = create(:user, :without_profile, profile_image: nil, username: username)

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
        OmniAuth.config.on_failure = OmniauthHelpers.const_get(:OMNIAUTH_DEFAULT_FAILURE_HANDLER)
      end

      it "does not create a new user or log in and notifies Datadog", :aggregate_failures do
        omniauth_setup_authentication_error(nil, params)

        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.not_to change(User, :count)

        expect(page).to have_current_path("/users/sign_in")
        expect(page).to have_button(sign_in_link)

        args = omniauth_failure_args(nil, "apple", params)
        expect(ForemStatsClient).to have_received(:increment).with(
          "omniauth.failure", *args
        )
      end
    end

    context "when a validation failure occurs" do
      before do
        # A User is invalid if their name is more than 100 chars long
        OmniAuth.config.mock_auth[:apple].info.first_name = "X" * 101
      end

      it "does not create a new user, redirects to registration, and does not log errors", :aggregate_failures do
        allow(Rails.error).to receive(:report)

        expect do
          visit sign_up_path
          click_on(sign_in_link, match: :first)
        end.not_to change(User, :count)

        expect(page).to have_current_path("/users/sign_up")
        expect(Rails.error).not_to have_received(:report)
      end
    end
  end

  context "when a user already exists" do
    let!(:auth_payload) { OmniAuth.config.mock_auth[:apple] }
    let(:user) { create(:user, :without_profile, :with_identity, identities: [:apple]) }

    before do
      # Apple sends nil as `first_name` and `last_name` for an existing user
      auth_payload.info.first_name = auth_payload.info.last_name = nil
      auth_payload.info.email = user.email
    end

    after do
      sign_out user
    end

    it "logs in with valid credentials and redirects to the feed when already signed in", :aggregate_failures do
      visit sign_up_path
      click_on(sign_in_link, match: :first)

      expect(page).to have_current_path("/?signin=true")

      visit user_apple_omniauth_authorize_path

      expect(page).to have_current_path("/?signin=true")
    end
  end
end
