require "rails_helper"

RSpec.describe "Users" do
  describe "GET /users" do
    let(:user) { create(:user, username: "Sloan") }

    context "when no state params are present" do
      it "returns no users" do
        sign_in user
        get users_path

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to be_empty
      end
    end

    context "when sidebar_suggestions params are present" do
      it "returns no sidebar suggestions for an authenticated user" do
        sign_in create(:user)

        get users_path(state: "sidebar_suggestions")

        expect(response.parsed_body).to be_empty
      end
    end
  end
end
