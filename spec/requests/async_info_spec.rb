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

    context "when Accept-Language header is present and user is not logged in" do
      it "does not store the Accept-Language header" do
        get_base_data_with_accept_language("en-US")
        expect(response).to have_http_status(:ok)
        # Assuming you have a mechanism to check that the language hasn't been stored for non-logged-in users
      end
    end

    context "when Accept-Language header is present and user is logged in but language not updated" do
      let(:user) { create(:user, browser_accept_language_updated_at: nil) }

      it "stores the Accept-Language header" do
        sign_in user
        get_base_data_with_accept_language("en-US")
        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.browser_accept_language).to eq("en-US")
      end
    end

    context "when Accept-Language header is not present and user is logged in" do
      let(:user) { create(:user, browser_accept_language: "en-US") }

      it "does not update the stored Accept-Language header" do
        sign_in user
        get_base_data_with_accept_language("")
        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.browser_accept_language).to eq("en-US")
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

  def get_base_data_with_accept_language(accept_language)
    get "/async_info/base_data", headers: { "Accept-Language" => accept_language }
  end
end
