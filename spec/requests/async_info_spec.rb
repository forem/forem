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

      it "returns active announcement broadcast data and omits inactive announcements", :aggregate_failures do
        sign_in create(:user)
        inactive_broadcast = create(:announcement_broadcast, active: false)

        get "/async_info/base_data"
        expect(response.parsed_body["broadcast"]).to be_nil

        inactive_broadcast.update!(active: true)
        get "/async_info/base_data"
        expect(JSON.parse(response.parsed_body["broadcast"])).to include(
          "title" => inactive_broadcast.title,
          "html" => inactive_broadcast.processed_html,
        )
      end

      it "returns default_email_optin_allowed true if valid match with client geo" do
        sign_in create(:user)

        allow(controller_instance).to receive(:client_geolocation).and_return("US-NY")
        allow(Settings::General).to receive(:geos_with_allowed_default_email_opt_in).and_return(["US"])
        get "/async_info/base_data"
        expect(response.parsed_body["default_email_optin_allowed"]).to be(true)
      end

      it "updates the user's presence" do
        user = create(:user, last_presence_at: 2.hours.ago)
        sign_in user

        expect { get "/async_info/base_data" }.to change { user.reload.last_presence_at }
      end
    end
  end

  describe "GET /async_info/navigation_links" do
    it "returns html" do
      get "/async_info/navigation_links"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<div")
    end

    it "includes the hamburger create account tracking element only when signed out", :aggregate_failures do
      get "/async_info/navigation_links"
      expect(response.body).to include('data-tracking-id="ca_hamburger_home_page"')
      expect(response.body).to include('data-tracking-source="mobile_hamburger_nav"')

      sign_in create(:user)
      get "/async_info/navigation_links"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<div")
      expect(response.body).not_to include('data-tracking-id="ca_hamburger_home_page"')
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
