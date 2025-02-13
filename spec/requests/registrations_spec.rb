require "rails_helper"

RSpec.describe "Registrations" do
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

        expect(response.body).to include("By signing in")
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

    context "when subforem redirect conditions are met" do
      let!(:default_subforem) { create(:subforem, domain: "#{rand(10_000)}.com") }
      let!(:subforem) { create(:subforem, domain: "#{rand(10_000)}.com") }
      let!(:root_subforem) { create(:subforem, domain: "#{rand(10_000)}.com", root: true) }

      before do
        allow(RequestStore).to receive(:store).and_return(
          subforem_id: subforem.id,
          default_subforem_id: default_subforem.id,
          root_subforem_id: root_subforem.id
        )
      end

      it "redirects to the subforem enter path with the provided state" do
        get sign_up_path, params: { state: "new-user" }, headers: { "HTTP_HOST" => "#{subforem.domain}" }
        expected_url = URL.url("/enter?state=new-user", root_subforem)
        expect(response).to redirect_to(expected_url)
        expect(response.status).to eq 301
      end
    end

    context "when subforem_id is set but subforem record is not found" do
      let!(:subforem) { create(:subforem, domain: "#{rand(10_000)}.com") }
      let!(:default_subforem) { create(:subforem, domain: "#{rand(10_000)}.com") }
      let!(:root_subforem) { create(:subforem, domain: "#{rand(10_000)}.com", root: true) }
      before do
        allow(RequestStore).to receive(:store).and_return(
          subforem_id: subforem.id,
          default_subforem_id: subforem.id,
          root_subforem_id: root_subforem.id
        )
      end
      it "falls through and renders the normal sign up page" do
        get sign_up_path, params: { state: "new-user" }, headers: { "HTTP_HOST" => "#{subforem.domain}" }
        # The sign up page should render the email sign up option
        expect(response.status).to eq 200
        expect(response.body).to include("Already have an account?")
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
        # rubocop:disable RSpec/ReceiveMessages
        allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return("someSiteKey")
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:require_captcha_for_email_password_registration).and_return(true)
        # rubocop:enable RSpec/ReceiveMessages
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

    context "when going through the Creator Onboarding flow" do
      before do
        allow(Settings::General).to receive(:waiting_on_first_user).and_return(true)
        allow(Settings::UserExperience).to receive(:public).and_return(false)
      end

      it "renders the creator onboarding form" do
        get root_path
        expect(response.body).to include(CGI.escapeHTML("Let's start your Forem journey!"))
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
        get new_user_registration_path(forem_owner_secret: ENV.fetch("FOREM_OWNER_SECRET", nil))
        expect(response.body).not_to include("New Forem Secret")
        expect(response.body).to include(ENV.fetch("FOREM_OWNER_SECRET", nil))
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

      it "registers a user in good standing" do
        post "/users", params:
        { user: { name: "test #{rand(10)}",
                  username: "haha_#{rand(10)}",
                  email: "yoooo#{rand(100)}@yo.co",
                  password: "PaSSw0rd_yo000",
                  password_confirmation: "PaSSw0rd_yo000" } }

        new_user = User.last
        expect(new_user.registered).to be true
        expect(new_user.registered_at).not_to be_nil
        expect(new_user).not_to be_limited
      end

      it "limits the user if the admins have set new user status to limited" do
        allow(Settings::Authentication).to receive(:new_user_status).and_return("limited")

        user = build(:user)
        user_attributes = user.slice(:name, :username, :email)

        post "/users", params:
          { user: { **user_attributes, password: "Passw0rd!", password_confirmation: "Passw0rd!" } }

        new_user = User.last
        expect(new_user.registered).to be true
        expect(new_user.registered_at).not_to be_nil
        expect(new_user).to be_limited
      end

      it "logs in user and redirects to the root path" do
        user = build(:user)
        user_attributes = user.slice(:name, :username, :email)

        post "/users", params:
          { user: { **user_attributes, password: "Passw0rd!", password_confirmation: "Passw0rd!" } }

        new_user = User.last
        expect(new_user).to have_attributes(user_attributes)
        expect(controller.current_user).to eq(new_user)
        expect(response).to redirect_to(root_path)
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

    context "when email registration is allowed and confirmation is required" do
      before do
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
      end

      it "registers the user but does not log them in" do
        user = build(:user)
        user_attributes = user.slice(:name, :username, :email)

        post "/users", params:
          { user: { **user_attributes, password: "Passw0rd!", password_confirmation: "Passw0rd!" } }

        new_user = User.last
        expect(new_user.registered).to be true
        expect(new_user.registered_at).not_to be_nil
        expect(new_user).not_to be_limited
        expect(controller.current_user).to be_nil
        expect(response).to redirect_to(confirm_email_path(email: user.email))
      end

      it "also limits the user first if the admins have set new user status to limited" do
        allow(Settings::Authentication).to receive(:new_user_status).and_return("limited")

        user = build(:user)
        user_attributes = user.slice(:name, :username, :email)

        post "/users", params:
          { user: { **user_attributes, password: "Passw0rd!", password_confirmation: "Passw0rd!" } }

        new_user = User.last
        expect(new_user).to be_limited
        expect(controller.current_user).to be_nil
        expect(response).to redirect_to(confirm_email_path(email: user.email))
      end
    end

    context "when email registration allowed and email allow list empty" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
        # rubocop:disable RSpec/ReceiveMessages
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:allowed_registration_email_domains).and_return([])
        # rubocop:enable RSpec/ReceiveMessages
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
        # rubocop:disable RSpec/ReceiveMessages
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:allowed_registration_email_domains).and_return(["dev.to",
                                                                                                    "forem.com"])
        # rubocop:enable RSpec/ReceiveMessages
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
        # rubocop:disable RSpec/ReceiveMessages
        allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return("someSiteKey")
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(true)
        allow(Settings::Authentication).to receive(:require_captcha_for_email_password_registration).and_return(true)
        # rubocop:enable RSpec/ReceiveMessages
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

      it "logs in user and redirects them to the creator settings path" do
        user = build(:user)
        user_attributes = user.slice(:name, :username, :email)

        post "/users", params:
          { user: { **user_attributes, password: "Passw0rd!", password_confirmation: "Passw0rd!" } }

        new_user = User.first
        expect(new_user.registered).to be true
        expect(new_user.registered_at).not_to be_nil
        expect(controller.current_user).to eq(new_user)
        expect(response).to redirect_to(new_admin_creator_setting_path)
      end

      it "makes user super admin and config admin" do
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.first.super_admin?).to be true
        expect(User.first.trusted?).to be true
        expect(User.first.creator?).to be true
        expect(User.first.limited?).to be false
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
        expect(User.first.super_admin?).to be true
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
          expect(User.first).to be_nil
        end.to raise_error Pundit::NotAuthorizedError
      end

      it "enqueues Discover::RegisterWorker" do
        sidekiq_assert_enqueued_with(job: Discover::RegisterWorker) do
          post "/users", params:
            { user: { name: "test #{rand(10)}",
                      username: "haha_#{rand(10)}",
                      email: "yoooo#{rand(100)}@yo.co",
                      forem_owner_secret: "test",
                      password: "PaSSw0rd_yo000",
                      password_confirmation: "PaSSw0rd_yo000" } }
        end
      end
    end

    context "when going through the Creator Onboarding flow" do
      before do
        allow_any_instance_of(ProfileImageUploader).to receive(:download!)
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
        expect(User.first.super_admin?).to be true
        expect(User.first.trusted?).to be true
        expect(User.first.creator?).to be true
        expect(User.first.limited?).to be false
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
