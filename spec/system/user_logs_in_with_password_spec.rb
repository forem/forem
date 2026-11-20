require "rails_helper"

RSpec.describe "Authenticating with a password" do
  def submit_login_form(email, password)
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    within("#sign-in-password-form") do
      fill_in "Email", with: email
      fill_in "Password", with: password
      click_on "Log in"
    end
  end

  let(:password) { "p4assw0rd" }
  let!(:user) do
    create(:user, :without_profile, profile_image: nil, password: password, password_confirmation: password)
  end

  before do
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

  context "when logging in with incorrect or valid credentials" do
    it "displays errors for wrong email or password and signs in with the correct password", :aggregate_failures do
      visit sign_up_path

      submit_login_form("wrong@example.com", password)
      expect(page).to have_text("Unable to login.")

      submit_login_form(user.email, "wr0ng")
      expect(page).to have_text("Unable to login.")

      submit_login_form(user.email, password)
      expect(page).to have_current_path("/?signin=true")
    end

    it "sends an email with the unlock link if the user gets locked out", :aggregate_failures do
      allow(User).to receive(:maximum_attempts).and_return(1)
      visit sign_up_path

      assert_enqueued_with(job: Devise.mailer.delivery_job) do
        submit_login_form(user.email, "wr0ng")
      end

      expect(enqueued_jobs.first[:args]).to match(array_including("unlock_instructions"))
    end
  end

  context "when the user's account is locked" do
    it "allows the user to unlock their account via social logins", :aggregate_failures do
      omniauth_mock_github_payload
      auth_payload = OmniAuth.config.mock_auth[:github]
      auth_payload.info.email = user.email
      user.lock_access!

      visit sign_up_path
      click_on("Continue with GitHub", match: :first)

      expect(page).to have_current_path("/?signin=true")
      expect(page).to have_no_text("Your account is locked.")
    end
  end
end
