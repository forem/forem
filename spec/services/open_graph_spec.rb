require "rails_helper"

describe OpenGraph, :vcr, type: :service do
  VCR.use_cassette("open_graph") do
    let(:page) { described_class.new("https://github.com/forem") }
  end

  describe "meta-programmed methods" do
    it "calls the methods" do
      expect(page.title).to eq("Forem · GitHub")
      expect(page.url).to eq("https://github.com/forem")
      expect(page.description).to include("Forem has 18 repositories available. Follow their code on GitHub.")
    end
  end

  describe ".meta_for" do
    it "gets a specific meta value" do
      expect(page.meta_for("twitter:card")).to eq("summary_large_image")
      expect(page.meta_for("enabled-features")).to eq("MARKETPLACE_PENDING_INSTALLATIONS")
      expect(page.meta_for("theme-color")).to eq("#1e2327")
    end
  end

  describe "twitter" do
    it "returns twitter data" do
      expect(page.twitter["twitter:site"]).to eq "@github"
      expect(page.twitter["twitter:title"]).to eq "Forem"
      expect(page.twitter["twitter:card"]).to eq "summary_large_image"
    end

    it "returns empty hash when not available" do
      allow(page).to receive(:twitter).and_return({})

      expect(page.twitter).to be_blank
    end
  end

  describe "grouped by key" do
    it "groups open graph properties" do
      expect(page.grouped_properties).to have_key("fb")
      expect(page.grouped_properties).to have_key("og")
      expect(page.grouped_properties).to have_key("profile")
    end

    # not an exhaustive check but will check a couple of the more popular ones
    # and make sure they're grouped
    it "groups metadata" do
      expect(page.grouped_meta).to have_key("og")
      expect(page.grouped_meta).to have_key("twitter")
      expect(page.grouped_meta["og"].size).to eq 7
      expect(page.grouped_meta["og"].class).to eq Hash
      expect(page.grouped_meta["twitter"].size).to eq 5
      expect(page.grouped_meta["twitter"].class).to eq Hash
    end
  end

  # Regression tests for GHSA-v8wj-4j4p-c2gc:
  # SSRF bypass via HTTP 302 redirect in fetch_html.
  # An attacker's public URL passes validate_link's HEAD guard but redirects
  # the metadata GET to an internal/loopback address. safe_fetch_html must
  # intercept and reject each redirect hop before following it.
  describe "#safe_fetch_html SSRF redirect protection", type: :service do
    let(:instance) { described_class.allocate } # bypass initialize / live HTTP
    let(:public_url) { "http://attacker.example/page" }
    let(:internal_loopback) { "http://127.0.0.1:9931/secret" }
    let(:internal_rfc1918) { "http://169.254.169.254/latest/meta-data/" }

    before do
      # Silence logger output for blocked-redirect warnings in test output.
      allow(Rails.logger).to receive(:warn)
      allow(Addrinfo).to receive(:getaddrinfo)
        .with("attacker.example", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])
      allow(Addrinfo).to receive(:getaddrinfo)
        .with("bounce.example", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])
    end

    it "blocks a redirect to a loopback address (core SSRF regression)" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => internal_loopback })

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to be_nil
      # The internal loopback should never have been requested.
      expect(a_request(:get, internal_loopback)).not_to have_been_made
    end

    it "blocks a redirect to a cloud-metadata link-local address" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => internal_rfc1918 })

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to be_nil
      expect(a_request(:get, internal_rfc1918)).not_to have_been_made
    end

    it "follows redirects to public URLs normally" do
      redirect_target = "http://destination.example/page"
      expected_body = "<html><title>Public Page</title></html>"

      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => redirect_target })
      stub_request(:get, redirect_target)
        .to_return(status: 200, body: expected_body)

      # Stub DNS so private_ip? approves both hosts
      allow(Addrinfo).to receive(:getaddrinfo)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to eq(expected_body)
    end

    it "returns nil and does not raise when Location header is missing on a redirect" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: {})

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to be_nil
    end

    it "returns nil gracefully after exhausting the redirect hop limit" do
      bounce = "http://bounce.example/"

      allow(Addrinfo).to receive(:getaddrinfo)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])
      # Every hop redirects back to itself
      stub_request(:get, bounce).to_return(status: 302, headers: { "Location" => bounce })

      result = instance.__send__(:safe_fetch_html, bounce)

      expect(result).to be_nil
    end

    it "blocks a scheme-relative redirect to a private host (//evil.internal/...)" do
      scheme_relative_target = "http://evil.internal/secret"

      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => "//evil.internal/secret" })

      # evil.internal resolves to a private IP
      allow(Addrinfo).to receive(:getaddrinfo).with("evil.internal", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "10.0.0.5")])
      # attacker.example resolves to public (for the initial request)
      allow(Addrinfo).to receive(:getaddrinfo).with("attacker.example", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to be_nil
      expect(a_request(:get, scheme_relative_target)).not_to have_been_made
    end

    it "blocks a redirect to an IPv4-mapped IPv6 loopback address" do
      ipv6_target = "http://[::ffff:127.0.0.1]/secret"

      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => ipv6_target })

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to be_nil
    end

    it "returns nil for non-HTTP Location headers (javascript:, data:, etc.)" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => "javascript:alert(1)" })

      result = instance.__send__(:safe_fetch_html, public_url)

      # javascript: URI has nil host → private_ip?(nil) → true (deny)
      expect(result).to be_nil
    end

    it "blocks on a multi-hop chain where the final hop targets a private address" do
      hop1 = "http://hop1.example/page"
      hop2 = "http://127.0.0.1:8080/admin"

      allow(Addrinfo).to receive(:getaddrinfo).with("hop1.example", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.20")])
      allow(Addrinfo).to receive(:getaddrinfo).with("attacker.example", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])

      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => hop1 })
      stub_request(:get, hop1)
        .to_return(status: 302, headers: { "Location" => hop2 })

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to be_nil
      expect(a_request(:get, hop2)).not_to have_been_made
    end

    it "caches a nil result for blocked redirects, preventing repeated outbound requests" do
      # Use a real memory store for this test since the test env may use NullStore
      real_cache = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(real_cache)

      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => internal_loopback })

      # First call — hits the network
      result1 = instance.__send__(:fetch_html, public_url)
      expect(result1).to be_nil

      # Second call — should be served from cache, NOT hitting the network again
      result2 = instance.__send__(:fetch_html, public_url)
      expect(result2).to be_nil

      # The public URL should have been requested only once (cached after that)
      expect(a_request(:get, public_url)).to have_been_made.once
    end

    it "blocks SSRF when initializing OpenGraph directly without fallback requests" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => internal_loopback })

      og = described_class.new(public_url)

      expect(og.title).to be_blank
      expect(a_request(:get, internal_loopback)).not_to have_been_made
    end

    it "blocks direct requests to private IPs upfront without network requests" do
      og = described_class.new(internal_loopback)

      expect(og.title).to be_blank
      expect(a_request(:get, internal_loopback)).not_to have_been_made
    end

    it "blocks non-HTTP/HTTPS redirect targets (e.g. ftp://)" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => "ftp://internal.example/file" })

      result = instance.__send__(:safe_fetch_html, public_url)

      expect(result).to be_nil
      expect(a_request(:any, "ftp://internal.example/file")).not_to have_been_made
    end
  end
end
