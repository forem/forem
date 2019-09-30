require "rails_helper"

RSpec.describe "History", type: :request do
  let(:user) { create(:user) }
  let(:pro_user) { create(:user, :pro) }
  let(:pro_membership_user) { create(:user, :with_pro_membership) }

  describe "GET /history" do
    it "does not allow access to a regular user" do
      sign_in user
      expect { get history_path }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "allows access to a pro user" do
      sign_in pro_user
      get history_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("History")
    end

    it "allows access to a user with a pro membership" do
      sign_in pro_membership_user
      get history_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("History")
    end
  end
end
