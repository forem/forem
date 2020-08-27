require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  describe "GET /enter" do
    context "when not logged in" do
      it "shows the sign in page (with self-serve auth)" do
        get "/enter"
        expect(response.body).to include "Great to have you"
      end

      it "shows the sign in text" do
        get "/enter"
        expect(response.body).to include "If you have a password"
      end

      it "shows invite-only text if no self-serve" do
        SiteConfig.authentication_providers = []
        get "/enter"
        expect(response.body).to include "If you have a password"
        expect(response.body).not_to include "Sign in by social auth"
      end
    end

    context "when logged in" do
      it "redirects to /dashboard" do
        sign_in user

        get "/enter"
        expect(response).to redirect_to("/dashboard")
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
  end
end
