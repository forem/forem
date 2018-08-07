require "rails_helper"

RSpec.describe "AsyncInfo", type: :request do
  let(:user) { build(:user) }

  describe "GET /async_info/base_data" do
    describe "anonymous user" do
      before do
        get "/async_info/base_data"
      end

      it "returns token" do
        expect(response.body).to include("token")
      end

      it "does not return user" do
        expect(response.body).not_to include("user")
      end
    end

    describe "logged in user" do
      before do
        sign_in user
        get "/async_info/base_data"
      end

      it "returns token" do
        expect(response.body).to include("token")
      end

      it "does return user" do
        expect(response.body).to include("user")
      end
    end
  end
end
