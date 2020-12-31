require "rails_helper"

RSpec.describe "Shells", type: :request do
  describe "GET /shell_top" do
    it "renders file with proper text" do
      get "/shell_top"
      expect(response.body).to include("user-signed-in")
    end

    it "sends a surrogate key (for Fastly's user)" do
      get "/shell_top"
      expect(response.header["Surrogate-Key"]).to include("shell-top")
    end

    it "renders normal response even if site config is private" do
      allow(SiteConfig).to receive(:public).and_return(false)
      get "/shell_top"
      expect(response.body).to include("user-signed-in")
    end
  end

  describe "GET /shell_bottom" do
    it "renders file with proper text" do
      get "/shell_bottom"
      expect(response.body).to include("footer-container")
    end

    it "sends a surrogate key (for Fastly's user)" do
      get "/shell_bottom"
      expect(response.header["Surrogate-Key"]).to include("shell-bottom")
    end

    it "renders normal response even if site config is private" do
      allow(SiteConfig).to receive(:public).and_return(false)
      get "/shell_bottom"
      expect(response.body).to include("footer-container")
    end
  end
end
