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
end
