require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:user) { create(:user) }

  describe "GET /enter" do
    context "when not logged in" do
      it "shows the sign in page" do
        get "/enter"
        expect(response.body).to include "Great to have you"
      end
    end

    context "when logged in" do
      it "redirects to /dashboard" do
        sign_in user

        Timecop.freeze(Time.current) do
          get "/enter"
          expect(response).to redirect_to("/dashboard?signed-in-already&t=#{Time.current.to_i}")
        end
      end
    end
  end
end
