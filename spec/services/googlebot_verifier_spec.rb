# frozen_string_literal: true

require "rails_helper"

RSpec.describe GooglebotVerifier, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:googlebot_ip_ranges_url) { GooglebotVerifier::GOOGLEBOT_IP_RANGES_URL }
  let(:mock_response_body) do
    {
      creationTime: "2021-11-08T09:00:00Z",
      prefixes: [
        { ipv4Prefix: "66.249.64.0/27" },
        { ipv4Prefix: "66.249.66.0/24" },
        { ipv6Prefix: "2001:4860:4801:30::/64" }
      ]
    }.to_json
  end
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe ".googlebot?" do
    context "when API fetch is successful" do
      before do
        stub_request(:get, googlebot_ip_ranges_url)
          .to_return(status: 200, body: mock_response_body, headers: { "Content-Type" => "application/json" })
      end

      it "returns true for IPs inside the IPv4 ranges" do
        expect(described_class.googlebot?("66.249.64.1")).to be(true)
        expect(described_class.googlebot?("66.249.66.100")).to be(true)
      end

      it "returns true for IPs inside the IPv6 ranges" do
        expect(described_class.googlebot?("2001:4860:4801:30::1")).to be(true)
      end

      it "returns false for IPs outside the ranges" do
        expect(described_class.googlebot?("1.2.3.4")).to be(false)
        expect(described_class.googlebot?("2001:4860:4801:31::1")).to be(false)
      end

      it "returns false for invalid IPs" do
        expect(described_class.googlebot?("invalid-ip")).to be(false)
        expect(described_class.googlebot?("")).to be(false)
        expect(described_class.googlebot?(nil)).to be(false)
      end

      it "caches the prefixes for 24 hours and does not perform HTTP request on subsequent calls" do
        expect(described_class.googlebot?("66.249.64.1")).to be(true)
        
        # Stub subsequent calls to fail/timeout to verify cache is hit
        stub_request(:get, googlebot_ip_ranges_url).to_timeout

        expect(described_class.googlebot?("66.249.64.2")).to be(true)
        expect(described_class.googlebot?("1.2.3.4")).to be(false)
      end
    end

    context "when API fetch fails" do
      before do
        stub_request(:get, googlebot_ip_ranges_url).to_return(status: 500)
      end

      it "returns false for all IPs" do
        expect(described_class.googlebot?("66.249.64.1")).to be(false)
      end

      it "caches the empty failure response for 5 minutes" do
        expect(described_class.googlebot?("66.249.64.1")).to be(false)

        # Stub subsequent call to succeed
        stub_request(:get, googlebot_ip_ranges_url)
          .to_return(status: 200, body: mock_response_body, headers: { "Content-Type" => "application/json" })

        # Should still return false due to the cached empty result
        expect(described_class.googlebot?("66.249.64.1")).to be(false)

        # Travel past the 5-minute cache window
        travel 6.minutes do
          expect(described_class.googlebot?("66.249.64.1")).to be(true)
        end
      end
    end
  end
end
