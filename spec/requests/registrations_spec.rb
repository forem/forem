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
      it "redirects to /dashboard" do
        sign_in user

        get sign_up_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
