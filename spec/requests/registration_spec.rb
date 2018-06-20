require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  describe "GET /enter" do
    context "when not logged in" do
      it "shows the sign in page" do
        get "/enter"
        expect(response.body).to include "Sign In or Create Your Account"
      end
    end

    context "when logged in" do
      it "redirects to /dashboard" do
        login_as user
        get "/enter"
        is_expected.to redirect_to("/dashboard?signed-in-already&t=#{Time.now.to_i}")
      end
    end
  end
end
