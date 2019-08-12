require "rails_helper"

RSpec.describe "Api::V0::Users", type: :request do
  def json_response
    JSON.parse(response.body)
  end

  describe "GET /api/users/me" do
    it "requires request to be authenticated" do
      get me_api_users_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "when request is authenticated" do
      let_it_be(:user)         { create(:user) }
      let_it_be(:access_token) { create(:doorkeeper_access_token, resource_owner: user) }

      it "return user's information" do
        get me_api_users_path, params: { access_token: access_token.token }
        expect(json_response["username"]).to eq(user.username)
      end
    end
  end
end
