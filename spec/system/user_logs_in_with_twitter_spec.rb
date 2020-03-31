require "rails_helper"

def user_grants_authorization_on_twitter_popup(twitter_callback_hash)
  OmniAuth.config.add_mock(:twitter, twitter_callback_hash)
end

def user_do_not_grants_authorization_on_twitter_popup
  OmniAuth.config.mock_auth[:twitter] = :invalid_credentials
end

RSpec.describe "Authenticating with twitter" do
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

  default_logger = Rails.logger

  # Override the default Rails logger as these tests require the Timber logger.
  before do
    timber_logger = Timber::Logger.new(nil)
    Rails.logger = ActiveSupport::TaggedLogging.new(timber_logger)
  end

  after { Rails.logger = default_logger }

  context "when user is new on dev.to" do
    it "logging in with twitter using valid credentials" do
      user_grants_authorization_on_twitter_popup(twitter_callback_hash)

      visit root_path
      click_link "Sign In With Twitter"

      expect(page.html).to include("onboarding-container")
    end

    it "logging in with twitter using invalid credentials" do
      user_do_not_grants_authorization_on_twitter_popup

      visit root_path
      click_link "Sign In With Twitter"

      expect(page).to have_link "Sign In/Up"
      expect(page).to have_link "Via Twitter"
      expect(page).to have_link "Via GitHub"
      expect(page).to have_link "All about #{ApplicationConfig['COMMUNITY_NAME']}"
    end
  end
end
