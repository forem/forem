require "rails_helper"

RSpec.describe "AsyncInfo", type: :request do
  let(:controller_instance) { AsyncInfoController.new }

  before do
    allow(AsyncInfoController).to receive(:new).and_return(controller_instance)
  end

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

    context "when logged in" do
      it "returns token and user" do
        allow(controller_instance).to receive(:remember_user_token).and_return(nil)
        sign_in create(:user)
        get "/async_info/base_data"
        expect(response.body).to include("token", "user")
      end
    end
  end

  describe "GET /async_info/shell_version" do
    it "returns shell_version" do
      get "/async_info/shell_version"
      expect(response.body).to include("version")
    end
  end

  describe "#remember_user_token" do
    # We require the remember_user_token key bc we also use it for caching in Fastly
    # If this key changes, Fastly needs to be updated
    it "requires remember_user_token cookie to be present" do
      get "/async_info/base_data"
      token = "a_token"
      controller.send("cookies")[:remember_user_token] = "a_token"
      expect(controller.remember_user_token).to eq(token)
    end
  end
end
