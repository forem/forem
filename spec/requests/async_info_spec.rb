require "rails_helper"

RSpec.describe "AsyncInfo", type: :request do
  describe "GET /async_info/base_data" do
    context "when not logged-in" do
      before { get "/async_info/base_data" }

      it "returns token" do
        expect(response.body).to include("token")
      end

      it "does not return user" do
        expect(response.body).not_to include("user")
      end
    end

    context "when logged int" do
      it "returns token and user" do
        allow(cookies).to receive(:[]).with(:remember_user_token).and_return(nil)
        sign_in create(:user)
        get "/async_info/base_data"
        expect(response.body).to include("token", "user")
      end
    end
  end
end
