require "rails_helper"

RSpec.describe "Stories::ArticlesSearchController" do
  describe "GET query page" do
    it "renders page with proper header" do
      get "/search?q=hello"
      expect(response.body).to include(CGI.escapeHTML("=> Search Results"))
    end

    context "with non-empty query" do
      it "renders search term in page title" do
        get "/search?q=hello"
        expect(response.body).to include("Search results for hello")
      end
    end

    context "with empty query" do
      it "renders default page title" do
        get "/search?q="
        expect(response.body).to include("Search results")
      end
    end

    context "when Algolia branding is enabled" do
      before do
        allow(Settings::General).to receive(:display_algolia_branding).and_return(true)
      end

      it "renders the Algolia attribution item with responsive layout class" do
        get "/search?q=hello"
        expect(response.body).to include("search-powered-by")
        expect(response.body).to include(I18n.t("views.search.powered_by"))
      end
    end

    context "when Algolia branding is disabled" do
      before do
        allow(Settings::General).to receive(:display_algolia_branding).and_return(false)
      end

      it "omits the Algolia attribution item" do
        get "/search?q=hello"
        expect(response.body).not_to include("search-powered-by")
      end
    end
  end
end
