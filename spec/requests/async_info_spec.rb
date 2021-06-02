require "rails_helper"

RSpec.describe "AsyncInfo", type: :request do
  let(:controller_instance) { AsyncInfoController.new }

  before do
    allow(AsyncInfoController).to receive(:new).and_return(controller_instance)
  end

  describe "GET /async_info/base_data" do
    context "when not logged-in" do
      it "returns json without user" do
        get "/async_info/base_data"
        expect(response.parsed_body.keys).to match_array(%w[broadcast param token])
      end

      it "renders normal response even if the Forem instance is private" do
        allow(Settings::UserExperience).to receive(:public).and_return(false)
        get "/async_info/base_data"
        expect(response.parsed_body.keys).to match_array(%w[broadcast param token])
      end
    end

    context "when logged in" do
      it "returns token and user" do
        sign_in create(:user)

        get "/async_info/base_data"
        expect(response.parsed_body.keys).to match_array(%w[broadcast param token user])
      end
    end
  end

  describe "GET /async_info/shell_version" do
    it "returns shell_version" do
      get "/async_info/shell_version"
      expect(response.body).to include("version")
    end
  end
end
