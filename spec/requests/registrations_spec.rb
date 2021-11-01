require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  describe "Log In" do
    context "when not logged in" do
      it "shows the sign in page with single sign on options" do
        get sign_up_path

        Authentication::Providers.enabled.each do |provider_name|
          provider = Authentication::Providers.get!(provider_name)

          expect(response.body).to include("Continue with #{provider.official_name}")
        end
      end

      it "only shows the single sign on options if they are present" do
        allow(Authentication::Providers).to receive(:enabled).and_return([])
        allow(Settings::Authentication).to receive(:allow_email_password_login).and_return(false)

        get sign_up_path

        expect(response.body).not_to include("Have a password? Log in")
      end
    end

    context "when email login is enabled in /admin/customization/config" do
      before do
        allow(Settings::Authentication).to receive(:allow_email_password_login).and_return(true)
      end

      it "shows the sign in text for password based authentication" do
        get sign_up_path

        expect(response.body).to include("Have a password? Continue with your email address")
      end
    end

    context "when email login is disabled in /admin/customization/config" do
      before do
        allow(Settings::Authentication).to receive(:allow_email_password_login).and_return(false)
      end

      it "does not show the sign in text for password based authentication" do
        get sign_up_path

        expect(response.body).not_to include("Have a password? Log in")
      end
    end

    context "when logged in" do
      it "redirects to main feed" do
        sign_in user

        get sign_up_path
        expect(response).to redirect_to("/?signin=true")
      end
    end
  end

  describe "Create Account" do
    context "when email registration allowed" do
      before do
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
      end

      it "shows the sign in page with email option" do
        get sign_up_path, params: { state: "new-user" }

        expect(response.body).to include("Sign up with Email")
      end

      it "shows the sign in text for password based authentication" do
        get sign_up_path, params: { state: "new-user" }

        expect(response.body).to include("Already have an account? <a href=\"/enter\">Log in</a>")
      end

      it "persists uploaded image" do
        name = "test"
        image_path = Rails.root.join("spec/support/fixtures/images/image1.jpeg")
        post users_path, params: {
          user: {
            name: name,
            username: "username",
            email: "yo@whatup.com",
            password: "password",
            password_confirmation: "password",
            profile_image: Rack::Test::UploadedFile.new(image_path, "image/jpeg")
          }
        }
        expect(File.read(User.last.profile_image.file.file)).to eq(File.read(image_path))
      end

      it "creates a user with a random profile image if none was uploaded" do
        name = "test"
        post users_path, params: {
          user: {
            name: name,
            username: "username",
            email: "yo@whatup.com",
            password: "password",
            password_confirmation: "password"
          }
        }

        expect(User.find_by(name: name).persisted?).to be true
      end
    end

    context "when email registration not allowed" do
      before { allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(false) }

      it "does not show email sign up option" do
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(false)
        get sign_up_path, params: { state: "new-user" }

        expect(response.body).not_to include("Sign up with Email")
      end
    end

    context "when email registration allowed and captcha required" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
        allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return("someSiteKey")
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:require_captcha_for_email_password_registration).and_return(true)
      end

      it "displays the captcha box on email signup page" do
        get sign_up_path, params: { state: "email_signup" }

        expect(response.body).to include("recaptcha-tag-container")
      end
    end

    context "when user logged in" do
      it "redirects to main feed" do
        sign_in user

        get sign_up_path
        expect(response).to redirect_to("/?signin=true")
      end
    end

    context "with the creator_onboarding feature flag" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:creator_onboarding).and_return(true)
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)
        allow(Settings::UserExperience).to receive(:public).and_return(false)
      end

      it "renders the creator onboarding form" do
        get root_path
        expect(response.body).to include("Let's start your Forem journey!")
        expect(response.body).to include("Create your admin account first")
      end
    end
  end

  describe "GET /users/signup" do
    context "when site is in waiting_on_first_user state" do
      before do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)
        ENV["FOREM_OWNER_SECRET"] = "test"
      end

      after do
        ENV["FOREM_OWNER_SECRET"] = nil
      end

      it "auto-populates forem_owner_secret if included in querystring params" do
        get new_user_registration_path(forem_owner_secret: ENV["FOREM_OWNER_SECRET"])
        expect(response.body).not_to include("New Forem Secret")
        expect(response.body).to include(ENV["FOREM_OWNER_SECRET"])
      end

      it "shows forem_owner_secret field if it's not included in querystring params" do
        get new_user_registration_path
        expect(response.body).to include("New Forem Secret")
      end
    end
  end

  describe "POST /users" do
    def mock_recaptcha_verification
      allow_any_instance_of(RegistrationsController).to(
        receive(:recaptcha_verified?).and_return(true),
      )
      # rubocop:enable RSpec/AnyInstance
    end

    context "when site is not configured to accept email registration" do
      before do
        allow(Settings::Authentication)
          .to receive(:allow_email_password_registration).and_return(false)
      end

      it "disallows communities where email registration is not allowed" do
        expect { post "/users" }.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when site is configured to accept email registration" do
      before do
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
      end

      it "does not raise disallowed if community is set to allow email" do
        expect { post "/users" }.not_to raise_error
      end

      it "does not create user with invalid params" do
        post "/users"
        expect(User.all.size).to be 0
      end

      it "creates user with valid params passed" do
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 1
      end

      it "marks as registerd" do
        post "/users", params:
        { user: { name: "test #{rand(10)}",
                  username: "haha_#{rand(10)}",
                  email: "yoooo#{rand(100)}@yo.co",
                  password: "PaSSw0rd_yo000",
                  password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.last.registered).to be true
        expect(User.last.registered_at).not_to be nil
      end

      it "does not create user with password confirmation mismatch" do
        post "/users", params:
        { user: { name: "test #{rand(100)}",
                  username: "haha_#{rand(100)}",
                  email: "yoooo#{rand(100)}@yo.co",
                  password: "PaSSw0rd_yo000",
                  password_confirmation: "PaSSw0rd_yo000ooooooo" } }
        expect(User.all.size).to be 0
      end

      it "does not create user with no email address" do
        post "/users", params:
        { user: { name: "test #{rand(10)}",
                  username: "haha_#{rand(10)}",
                  email: "",
                  password: "PaSSw0rd_yo000",
                  password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 0
      end
    end

    context "when email registration allowed and email allow list empty" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:allowed_registration_email_domains).and_return([])
      end

      it "creates user when email in allow list" do
        post "/users", params:
        { user: { name: "royal #{rand(10)}",
                  username: "magoo_#{rand(10)}",
                  email: "queenelizabeth@dev.to",
                  password: "PaSSw0rd_yo000",
                  password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 1
      end
    end

    context "when email registration allowed and email allow list present" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:allowed_registration_email_domains).and_return(["dev.to",
                                                                                                    "forem.com"])
      end

      it "does not create user when email not in allow list" do
        post "/users", params:
        { user: { name: "ronald #{rand(10)}",
                  username: "mcdonald_#{rand(10)}",
                  email: "ronald@mcdonald.com",
                  password: "PaSSw0rd_yo000",
                  password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 0
      end

      it "creates user when email in allow list" do
        post "/users", params:
        { user: { name: "royal #{rand(10)}",
                  username: "magoo_#{rand(10)}",
                  email: "queenelizabeth@dev.to",
                  password: "PaSSw0rd_yo000",
                  password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 1
      end
    end

    context "when Forem instance configured to accept email registration AND require captcha" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
        allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return("someSiteKey")
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:require_captcha_for_email_password_registration).and_return(true)
      end

      it "creates user when valid params passed and recaptcha completed" do
        mock_recaptcha_verification
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 1
      end

      it "does not create user when valid params passed BUT recaptcha incomplete" do
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 0
        expect(response).to redirect_to("/users/sign_up?state=email_signup")

        follow_redirect!
        expect(response.body).to include("You must complete the recaptcha")
      end
    end

    context "when site is in waiting_on_first_user state" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)
        ENV["FOREM_OWNER_SECRET"] = nil
      end

      after do
        ENV["FOREM_OWNER_SECRET"] = nil
      end

      it "does not raise disallowed" do
        expect { post "/users" }.not_to raise_error
      end

      it "creates user with valid params passed" do
        user_email = "yoooo#{rand(100)}@yo.co"
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: user_email,
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 2
        expect(User.first.email).to eq user_email
      end

      it "makes user super admin and config admin" do
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.first.has_role?(:super_admin)).to be true
        expect(User.first.has_role?(:trusted)).to be true
      end

      it "creates mascot user" do
        expect(Settings::General.mascot_user_id).to be_nil
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(Settings::General.mascot_user_id).to eq User.last.id

        mascot_account = User.mascot_account
        expect(mascot_account.username).to eq Users::CreateMascotAccount::MASCOT_PARAMS[:username]
        expect(mascot_account.email).to eq Users::CreateMascotAccount::MASCOT_PARAMS[:email]
      end

      it "creates super admin with valid params in FOREM_OWNER_SECRET scenario" do
        ENV["FOREM_OWNER_SECRET"] = "test"
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    forem_owner_secret: "test",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.first.has_role?(:super_admin)).to be true
      end

      it "does not authorize request in FOREM_OWNER_SECRET scenario if not passed correct value" do
        ENV["FOREM_OWNER_SECRET"] = "test"
        expect do
          post "/users", params:
            { user: { name: "test #{rand(10)}",
                      username: "haha_#{rand(10)}",
                      email: "yoooo#{rand(100)}@yo.co",
                      password: "PaSSw0rd_yo000",
                      forem_owner_secret: "not_test",
                      password_confirmation: "PaSSw0rd_yo000" } }
          expect(User.first).to be nil
        end.to raise_error Pundit::NotAuthorizedError
      end

      it "enqueues Discover::RegisterWorker" do
        sidekiq_assert_enqueued_with(job: Discover::RegisterWorker) do
          post "/users", params:
            { user: { name: "test #{rand(10)}",
                      username: "haha_#{rand(10)}",
                      email: "yoooo#{rand(100)}@yo.co",
                      password: "PaSSw0rd_yo000",
                      forem_owner_secret: "test",
                      password_confirmation: "PaSSw0rd_yo000" } }
        end
      end
    end

    context "with the creator_onboarding feature flag" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
        allow(FeatureFlag).to receive(:enabled?).with(:creator_onboarding).and_return(true)
        allow(FeatureFlag).to receive(:enabled?).with(:runtime_banner).and_return(false)
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)
      end

      it "creates user with valid params passed" do
        user_email = "yoooo#{rand(100)}@yo.co"

        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: user_email,
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.all.size).to be 2
        expect(User.first.email).to eq user_email
      end

      it "makes user super admin and config admin" do
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.first.has_role?(:super_admin)).to be true
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
