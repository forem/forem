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
        expect(response.parsed_body.keys).to match_array(%w[broadcast client_geolocation creator
                                                            default_email_optin_allowed param token user])
      end

      it "returns default_email_optin_allowed true if valid match with client geo" do
        sign_in create(:user)

        allow(controller_instance).to receive(:client_geolocation).and_return("US-NY")
        allow(Settings::General).to receive(:geos_with_allowed_default_email_opt_in).and_return(["US"])
        get "/async_info/base_data"
        expect(response.parsed_body["default_email_optin_allowed"]).to be(true)
      end
    end
  end

  describe "GET /async_info/navigation_links" do
    it "returns html" do
      get "/async_info/navigation_links"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<div")
    end

    it "returns the correct 'default' navigation links" do
      default_navigation_link = create(:navigation_link)
      get "/async_info/navigation_links"
      expect(response.body).to include CGI.escapeHTML(default_navigation_link.name)
      expect(response.body).to include(default_navigation_link.url)
      expect(response.body).to include(default_navigation_link.icon)
    end

    it "returns the correct 'other' navigation links" do
      other_navigation_link = create(:navigation_link)
      other_navigation_link.other_section!

      get "/async_info/navigation_links"
      expect(response.body).to include CGI.escapeHTML(other_navigation_link.name)
      expect(response.body).to include(other_navigation_link.url)
      expect(response.body).to include(other_navigation_link.icon)
    end
  end
end
