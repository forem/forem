require "rails_helper"

RSpec.describe "AsyncInfo", type: :request do
  let(:user) { build(:user) }
  describe "GET /async_info/base_data" do
    it "returns token and no user for non-logged-in" do
      get "/async_info/base_data"
      expect(response.body).to include("token")
      expect(response.body).not_to include("user")
    end
    it "returns token and no user for non-logged-in" do
      sign_in user
      get "/async_info/base_data"
      expect(response.body).to include("token")
      expect(response.body).to include("user")
    end
  end
end
