# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack Sitemaps Throttling", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:googlebot_ip_ranges_url) { GooglebotVerifier::GOOGLEBOT_IP_RANGES_URL }
  let(:mock_response_body) do
    {
      creationTime: "2021-11-08T09:00:00Z",
      prefixes: [
        { ipv4Prefix: "66.249.64.0/27" }
      ]
    }.to_json
  end

  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear

    stub_request(:get, googlebot_ip_ranges_url)
      .to_return(status: 200, body: mock_response_body, headers: { "Content-Type" => "application/json" })
  end

  after do
    Rack::Attack.enabled = false
  end

  describe "sitemap_throttle" do
    context "when requested by a normal IP" do
      let(:headers) { { "REMOTE_ADDR" => "1.2.3.4" } }

      it "throttles sitemap requests to 10 per minute per IP" do
        10.times do
          get "/sitemap-index.xml", headers: headers
          expect(response).not_to have_http_status(:too_many_requests)
        end

        get "/sitemap-index.xml", headers: headers
        expect(response).to have_http_status(:too_many_requests)

        travel 1.minute + 1.second do
          get "/sitemap-index.xml", headers: headers
          expect(response).not_to have_http_status(:too_many_requests)
        end
      end

      it "does not throttle non-sitemap requests" do
        11.times do
          get "/about", headers: headers
          expect(response).not_to have_http_status(:too_many_requests)
        end
      end
    end

    context "when requested by a verified Googlebot IP" do
      let(:headers) { { "REMOTE_ADDR" => "66.249.64.1" } }

      it "does not throttle sitemap requests even beyond 10 requests per minute" do
        15.times do
          get "/sitemap-index.xml", headers: headers
          expect(response).not_to have_http_status(:too_many_requests)
        end
      end
    end

    context "when client IP spoofing Googlebot via User-Agent but not in Googlebot IP range" do
      let(:headers) do
        {
          "REMOTE_ADDR" => "1.2.3.4",
          "HTTP_USER_AGENT" => "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
        }
      end

      it "throttles sitemap requests to 10 per minute" do
        10.times do
          get "/sitemap-index.xml", headers: headers
          expect(response).not_to have_http_status(:too_many_requests)
        end

        get "/sitemap-index.xml", headers: headers
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end
end
