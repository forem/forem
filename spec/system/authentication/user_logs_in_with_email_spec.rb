require "rails_helper"

RSpec.describe "Authenticating with Email" do
  let(:sign_in_link) { "Continue" }
  let(:sign_up_link) { "Sign up with Email" }

  before do
    allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
    allow(Settings::Authentication).to receive(:allow_email_password_login).and_return(true)
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ProfileImageUploader).to receive(:download!)
    # rubocop:enable RSpec/AnyInstance
  end

  context "when a user is new" do
    let(:user) { build(:user, saw_onboarding: false) }

    context "when using valid credentials" do
      def sign_up_user
        visit sign_up_path(state: "new-user")
        click_link(sign_up_link, match: :first)

        fill_in_user(user)
        click_button("Sign up", match: :first)
      end

      it "creates a new user", js: true do
        expect do
          sign_up_user
        end.to change(User, :count).by(1)
      end

      it "logs in and redirects to email confirmation" do
        sign_up_user

        expect(page).to have_current_path("/confirm-email", ignore_query: true)
      end

      it "displays the properly decoded email" do
        decoded_email = user.email.sub("@", "+something@")
        user.email = decoded_email
        sign_up_user

        expect(page).to have_text(decoded_email)
      end
    end

    context "when trying to register with an already existing email" do
      it "shows an error" do
        email = "user@test.com"
        user = create(:user, email: email)

        expect do
          visit sign_up_path(state: "new-user")
          click_link(sign_up_link, match: :first)

          fill_in_user(user)
          click_button("Sign up", match: :first)
        end.not_to change(User, :count)

        expect(page).to have_current_path("/users", ignore_query: true)
        expect(page).to have_text("Email has already been taken")
      end
    end

    context "when using invalid credentials" do
      it "does not log in" do
        visit sign_up_path
        fill_in("user_email", with: "foo@bar.com")
        fill_in("user_password", with: "password")
        click_button("Continue", match: :first)

        expect(page).to have_current_path("/users/sign_in")
        expect(page).to have_text("Invalid Email or password.")
      end
    end
  end

  context "when a user already exists" do
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:user) { create(:user, password: password, password_confirmation: password) }

    after do
      sign_out user
    end

    context "when using valid credentials" do
      it "logs in" do
        visit sign_up_path
        log_in_user(user)

        expect(page).to have_current_path("/?signin=true")
      end

      it "logs in and redirects to onboarding if it hasn't been seen" do
        user.update(saw_onboarding: false)

        visit sign_up_path
        log_in_user(user)

        expect(page).to have_current_path("/onboarding", ignore_query: true)
        expect(page.html).to include("onboarding-container")
      end
    end

    context "when already signed in" do
      it "redirects to the feed" do
        sign_in user
        visit sign_up_path

        expect(page).to have_current_path("/?signin=true")
      end
    end
  end

  context "when community is in invite-only mode" do
    before do
      allow(ForemInstance).to receive(:invitation_only?).and_return(true)
    end

    it "doesn't present the authentication option" do
      visit sign_up_path(state: "new-user")
      expect(page).not_to have_text(sign_in_link)
      expect(page).to have_text("invite only")
    end
  end

  context "when requesting a password reset mail" do
    it "does not let malicious users enumerate email addresses" do
      visit new_user_session_path
      click_link "I forgot my password"
      fill_in "Email", with: "doesnotexist@example.com"
      click_button "Send me reset password instructions"

      expect(page).not_to have_text("Email not found")
    end
  end

  def fill_in_user(user)
    attach_file("user_profile_image", "spec/fixtures/files/podcast.png")
    fill_in("user_name", with: user.name)
    fill_in("user_username", with: user.username)
    fill_in("user_email", with: user.email)
    fill_in("user_password", with: "12345678")
    fill_in("user_password_confirmation", with: "12345678")
  end

  def log_in_user(user)
    fill_in("user_email", with: user.email)
    fill_in("user_password", with: user.password)
    click_button("Continue", match: :first)
  end
end
