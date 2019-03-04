require "rails_helper"

RSpec.describe "Delayed Job web interface", type: :request do
  let(:user)          { create(:user) }
  let(:super_admin)   { create(:user, :super_admin) }
  let(:article)       { create(:article, user_id: user.id) }

  describe "GET /delayed_job" do
    context "when not logged in" do
      it "raises 404" do
        expect do
          get "/delayed_job"
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when logged in" do
      it "raises 404" do
        login_as user
        expect do
          get "/delayed_job"
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "when logged in as a super admin" do
      before { login_as super_admin }

      it "redirects to overview" do
        get "/delayed_job"
        expect(response).to redirect_to("/delayed_job/overview")
      end

      it "renders overview" do
        get "/delayed_job/overview"
        expect(response.body).to include "Overview"
      end
    end
  end
end
