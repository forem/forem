require "rails_helper"

RSpec.describe SafeHttp, type: :service do
  let(:public_url) { "https://feeds.example/rss" }

  def resolve(host, ip)
    allow(Addrinfo).to receive(:getaddrinfo)
      .with(host, nil, nil, :STREAM)
      .and_return([instance_double(Addrinfo, ip_address: ip)])
  end

  before do
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    resolve("feeds.example", "203.0.113.10")
    resolve("other.example", "203.0.113.11")
  end

  it "returns the response for a public URL" do
    stub_request(:get, public_url).to_return(status: 200, body: "ok")

    response = described_class.get(public_url)

    expect(response.code).to eq(200)
    expect(response.body).to eq("ok")
  end

  it "passes options through to HTTParty" do
    stub_request(:get, public_url).with(headers: { "User-Agent" => "Forem Test" }).to_return(status: 200)

    expect(described_class.get(public_url, headers: { "User-Agent" => "Forem Test" }).code).to eq(200)
  end

  it "yields streamed body fragments" do
    stub_request(:get, public_url).to_return(status: 200, body: "streamed")
    body = +""

    described_class.get(public_url, stream_body: true) { |fragment| body << fragment.to_s }

    expect(body).to eq("streamed")
  end

  it "follows redirects to public hosts" do
    stub_request(:get, public_url).to_return(status: 301, headers: { "Location" => "https://other.example/feed" })
    stub_request(:get, "https://other.example/feed").to_return(status: 200, body: "moved")

    expect(described_class.get(public_url).body).to eq("moved")
  end

  it "resolves relative redirects against the current URL" do
    stub_request(:get, public_url).to_return(status: 302, headers: { "Location" => "/atom" })
    stub_request(:get, "https://feeds.example/atom").to_return(status: 200, body: "relative")

    expect(described_class.get(public_url).body).to eq("relative")
  end

  [
    "http://127.0.0.1/",
    "http://localhost:6379/",
    "http://10.0.0.5/admin",
    "http://169.254.0.1/",
    "http://[::1]/",
  ].each do |internal_url|
    it "blocks #{internal_url} without requesting it" do
      stub_request(:get, internal_url)

      expect { described_class.get(internal_url) }.to raise_error(described_class::BlockedUrlError)
      expect(a_request(:get, internal_url)).not_to have_been_made
    end
  end

  it "blocks a hostname that resolves to a private address" do
    resolve("internal.example", "10.1.2.3")
    stub_request(:get, "https://internal.example/")

    expect { described_class.get("https://internal.example/") }.to raise_error(described_class::BlockedUrlError)
    expect(a_request(:get, "https://internal.example/")).not_to have_been_made
  end

  it "blocks a redirect to an internal address without requesting it" do
    internal_url = "http://10.0.0.5/admin"
    stub_request(:get, public_url).to_return(status: 302, headers: { "Location" => internal_url })
    stub_request(:get, internal_url)

    expect { described_class.get(public_url) }.to raise_error(described_class::BlockedUrlError)
    expect(a_request(:get, internal_url)).not_to have_been_made
  end

  it "checks each redirect hop against validate_url before requesting it" do
    other_url = "https://other.example/feed"
    stub_request(:get, public_url).to_return(status: 302, headers: { "Location" => other_url })
    stub_request(:get, other_url)

    expect do
      described_class.get(public_url, validate_url: ->(url) { URI.parse(url).host == "feeds.example" })
    end.to raise_error(described_class::BlockedUrlError)
    expect(a_request(:get, other_url)).not_to have_been_made
  end

  it "blocks non-HTTP schemes" do
    expect { described_class.get("ftp://feeds.example/rss") }.to raise_error(described_class::BlockedUrlError)
  end

  it "gives up after too many redirects" do
    stub_request(:get, public_url).to_return(status: 302, headers: { "Location" => public_url })

    expect { described_class.get(public_url, max_redirects: 2) }
      .to raise_error(described_class::TooManyRedirectsError)
    expect(a_request(:get, public_url)).to have_been_made.times(3)
  end

  describe "connection pinning" do
    it "connects to the address that was validated" do
      stub_request(:get, public_url).to_return(status: 200)
      allow(HTTParty).to receive(:get).and_call_original

      described_class.get(public_url)

      expect(HTTParty).to have_received(:get).with(
        public_url,
        hash_including(
          connection_adapter: described_class::PinnedConnectionAdapter,
          connection_adapter_options: { pinned_address: "203.0.113.10" },
        ),
      )
    end

    it "resolves each hop once, so a later DNS answer cannot change the destination" do
      allow(Addrinfo).to receive(:getaddrinfo)
        .with("feeds.example", nil, nil, :STREAM)
        .and_return(
          [instance_double(Addrinfo, ip_address: "203.0.113.10")],
          [instance_double(Addrinfo, ip_address: "127.0.0.1")],
        )
      stub_request(:get, public_url).to_return(status: 200)
      allow(HTTParty).to receive(:get).and_call_original

      described_class.get(public_url)

      expect(Addrinfo).to have_received(:getaddrinfo).with("feeds.example", nil, nil, :STREAM).once
      expect(HTTParty).to have_received(:get)
        .with(public_url, hash_including(connection_adapter_options: { pinned_address: "203.0.113.10" }))
    end

    it "blocks a host when any of its addresses is non-public" do
      allow(Addrinfo).to receive(:getaddrinfo)
        .with("mixed.example", nil, nil, :STREAM)
        .and_return([
                      instance_double(Addrinfo, ip_address: "203.0.113.10"),
                      instance_double(Addrinfo, ip_address: "10.0.0.5"),
                    ])
      stub_request(:get, "https://mixed.example/")

      expect { described_class.get("https://mixed.example/") }.to raise_error(described_class::BlockedUrlError)
      expect(a_request(:get, "https://mixed.example/")).not_to have_been_made
    end

    it "keeps the hostname for the Host header and TLS while connecting to the pinned address" do
      options = { connection_adapter_options: { pinned_address: "203.0.113.10" } }
      http = described_class::PinnedConnectionAdapter.call(URI("https://feeds.example/rss"), options)

      expect(http.address).to eq("feeds.example")
      expect(http.ipaddr).to eq("203.0.113.10")
      expect(http.use_ssl?).to be(true)
    end

    it "disables environment proxy discovery on the pinned connection" do
      original_proxy = ENV.fetch("http_proxy", nil)
      ENV["http_proxy"] = "http://proxy.internal:8080"
      options = { connection_adapter_options: { pinned_address: "203.0.113.10" } }
      http = described_class::PinnedConnectionAdapter.call(URI("http://feeds.example/rss"), options)

      expect(http.proxy?).to be(false)
      expect(http.proxy_from_env?).to be(false)
      expect(http.ipaddr).to eq("203.0.113.10")
    ensure
      ENV["http_proxy"] = original_proxy
    end

    it "rejects explicit proxy options" do
      stub_request(:head, public_url)

      expect { described_class.head(public_url, http_proxyaddr: "proxy.internal") }
        .to raise_error(described_class::BlockedUrlError)
      expect(a_request(:head, public_url)).not_to have_been_made
    end
  end

  describe "cookies set during redirects" do
    it "sends them to later hops on the same host" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => "/actual.xml",
                                           "Set-Cookie" => "feed_session=abc; Path=/; HttpOnly" })
      stub_request(:get, "https://feeds.example/actual.xml")
        .with(headers: { "Cookie" => "feed_session=abc" })
        .to_return(status: 200, body: "with cookie")

      expect(described_class.get(public_url).body).to eq("with cookie")
    end

    it "keeps a Cookie header the caller supplied" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => "/actual.xml", "Set-Cookie" => "feed_session=abc" })
      stub_request(:get, "https://feeds.example/actual.xml")
        .with(headers: { "Cookie" => "pref=1; feed_session=abc" })
        .to_return(status: 200, body: "merged")

      expect(described_class.get(public_url, headers: { "Cookie" => "pref=1" }).body).to eq("merged")
    end

    it "does not send them to a different host" do
      stub_request(:get, public_url)
        .to_return(status: 302, headers: { "Location" => "https://other.example/feed",
                                           "Set-Cookie" => "feed_session=abc" })
      stub_request(:get, "https://other.example/feed").to_return(status: 200)

      described_class.get(public_url)

      expect(a_request(:get, "https://other.example/feed").with { |req| req.headers["Cookie"].nil? }).to have_been_made
    end
  end

  it "raises errors that callers rescuing HTTParty::Error already handle" do
    expect(described_class::BlockedUrlError.ancestors).to include(HTTParty::Error)
    expect(described_class::TooManyRedirectsError.ancestors).to include(HTTParty::Error)
  end

  describe ".head" do
    it "returns the response for a public URL" do
      stub_request(:head, public_url).to_return(status: 200)

      expect(described_class.head(public_url).code).to eq(200)
    end

    it "follows redirects to public hosts" do
      stub_request(:head, public_url).to_return(status: 302, headers: { "Location" => "https://other.example/feed" })
      stub_request(:head, "https://other.example/feed").to_return(status: 200)

      response = described_class.head(public_url)

      expect(response.code).to eq(200)
      expect(response.request.last_uri.to_s).to eq("https://other.example/feed")
    end

    it "blocks internal addresses without requesting them" do
      internal_url = "http://169.254.169.254/latest/meta-data/"
      stub_request(:head, internal_url)

      expect { described_class.head(internal_url) }.to raise_error(described_class::BlockedUrlError)
      expect(a_request(:head, internal_url)).not_to have_been_made
    end

    it "blocks a redirect to an internal address without requesting it" do
      internal_url = "http://127.0.0.1:8080/admin"
      stub_request(:head, public_url).to_return(status: 302, headers: { "Location" => internal_url })
      stub_request(:head, internal_url)

      expect { described_class.head(public_url) }.to raise_error(described_class::BlockedUrlError)
      expect(a_request(:head, internal_url)).not_to have_been_made
    end

    it "connects to the pinned address that was validated" do
      stub_request(:head, public_url).to_return(status: 200)
      allow(HTTParty).to receive(:head).and_call_original

      described_class.head(public_url)

      expect(HTTParty).to have_received(:head).with(
        public_url,
        hash_including(
          follow_redirects: false,
          connection_adapter: described_class::PinnedConnectionAdapter,
          connection_adapter_options: { pinned_address: "203.0.113.10" },
        ),
      )
    end
  end
end
