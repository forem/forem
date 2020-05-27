require "rails_helper"

RSpec.describe "ServiceWorker", type: :request do
  describe "GET /serviceworker.js" do
    xit "renders file with proper text" do
      get "/serviceworker.js"
      expect(response.body).to include("Serviceworkers file")
    end

    xit "renders javascript file" do
      get "/serviceworker.js"
      expect(response.header["Content-Type"]).to include("text/javascript")
    end

    xit "sends a surrogate key (for Fastly's user)" do
      get "/serviceworker.js"
      expect(response.header["Surrogate-Key"]).to include("serviceworker-js")
    end
  end

  describe "GET /manifest.json" do
    xit "renders file with proper text" do
      get "/manifest.json"
      expect(response.body).to include("\"name\": \"#{ApplicationConfig['COMMUNITY_NAME']} Community\"")
    end

    xit "renders json file" do
      get "/manifest.json"
      expect(response.header["Content-Type"]).to include("application/json")
    end

    xit "sends a surrogate key (for Fastly's user)" do
      get "/manifest.json"
      expect(response.header["Surrogate-Key"]).to include("manifest-json")
    end
  end
end
