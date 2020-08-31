require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  describe "Sign up" do
    context "when not logged in" do
      it "shows the sign in page with single sign on options" do
        get sign_up_path

        Authentication::Providers.enabled.each do |provider_name|
          provider = Authentication::Providers.get!(provider_name)

          expect(response.body).to include("Continue with #{provider.official_name}")
        end
      end

      it "shows the sign in text for password based authentication" do
        get sign_up_path

        expect(response.body).to include("Have a password? Continue with your email address")
      end

      it "does not show the password based authentication hint if there are no single sign in options enabled" do
        allow(Authentication::Providers).to receive(:enabled).and_return([])

        get sign_up_path

        expect(response.body).not_to include("Have a password? Continue with your email address")
      end

      it "only shows the single sign on options if they are present" do
        allow(Authentication::Providers).to receive(:enabled).and_return([])

        get sign_up_path

        expect(response.body).to include("Password")
        expect(response.body).not_to include("Continue with")
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

  describe "POST /users" do
    context "when site is not configured to accept email registration" do
      before do
        SiteConfig.allow_email_password_registration = false
      end

      it "disallows communities where email registration is not allowed" do
        expect { post "/users" }.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when site is configured to accept email registration" do
      before do
        SiteConfig.allow_email_password_registration = true
      end

      it "does not raise disallowed if community is set to allow email" do
        expect { post "/users" }.not_to raise_error Pundit::NotAuthorizedError
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

    context "when site is in waiting_on_first_user state" do
      before do
        SiteConfig.waiting_on_first_user = true
        ENV["FOREM_OWNER_SECRET"] = nil
      end

      after do
        SiteConfig.waiting_on_first_user = false
        ENV["FOREM_OWNER_SECRET"] = nil
      end

      it "does not raise disallowed" do
        expect { post "/users" }.not_to raise_error Pundit::NotAuthorizedError
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

      it "makes user super admin and config admin" do
        post "/users", params:
          { user: { name: "test #{rand(10)}",
                    username: "haha_#{rand(10)}",
                    email: "yoooo#{rand(100)}@yo.co",
                    password: "PaSSw0rd_yo000",
                    password_confirmation: "PaSSw0rd_yo000" } }
        expect(User.first.has_role?(:super_admin)).to be true
        expect(User.first.has_role?(:single_resource_admin, Config)).to be true
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
        expect(User.first.has_role?(:single_resource_admin, Config)).to be true
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
    end
  end
end
