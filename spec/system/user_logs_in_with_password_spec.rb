require "rails_helper"

RSpec.describe "Authenticating with a password" do
  def submit_login_form(email, password)
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Continue"
  end

  let(:password) { "p4assw0rd" }
  let!(:user) { create(:user, password: password, password_confirmation: password) }

  before do
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    visit sign_up_path
  end

  context "when logging in with incorrect credentials" do
    it "displays an error when the email address is wrong" do
      submit_login_form("wrong@example.com", password)

      expect(page).to have_text("Invalid Email or password.")
    end

    it "displays an error when the password is wrong" do
      submit_login_form(user.email, "wr0ng")
      expect(page).to have_text("Invalid Email or password.")
    end

    it "sends an email with the unlock link if the uset gets locked out" do
      allow(User).to receive(:maximum_attempts).and_return(1)

      expect do
        submit_login_form(user.email, "wr0ng")
      end.to change { Devise.mailer.deliveries.count }.by(1)
    end
  end

  context "when the user's account is locked" do
    it "allows the user to unlock their account via social logins" do
      omniauth_mock_github_payload
      auth_payload = OmniAuth.config.mock_auth[:github]
      create(:user, :with_identity, identities: [:github])
      auth_payload.info.email = user.email
      user.lock_access!

      visit sign_up_path
      click_on("Continue with GitHub", match: :first)

      expect(page).to have_current_path("/?signin=true")
      expect(page).not_to have_text("Your account is locked.")
    end
  end

  context "when logging in with the correct credentials" do
    it "allows the user to sign in with the correct password" do
      submit_login_form(user.email, password)
      expect(page).to have_current_path("/?signin=true")
    end
  end
end
