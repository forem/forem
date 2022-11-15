require "rails_helper"

RSpec.describe "AsyncInfo" do
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
        expect(response.parsed_body.keys).to match_array(%w[broadcast creator param token user])
      end
    end
  end

  describe "GET /async_info/navigation_links" do
    before do
      create_list(:navigation_link, 5)
      create_list(:navigation_link, 5, :other_section_link)
    end

    it "responds with existing navigation links" do
      get "/async_info/navigation_links"
      expect(response.parsed_body.keys).to match_array(%w[default_nav_links other_nav_links])
      expect(response.parsed_body["default_nav_links"].count).to eq(5)
      expect(response.parsed_body["other_nav_links"].count).to eq(5)
    end
  end
end
