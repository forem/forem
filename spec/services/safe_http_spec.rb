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

  it "blocks non-HTTP schemes" do
    expect { described_class.get("ftp://feeds.example/rss") }.to raise_error(described_class::BlockedUrlError)
  end

  it "gives up after too many redirects" do
    stub_request(:get, public_url).to_return(status: 302, headers: { "Location" => public_url })

    expect { described_class.get(public_url, max_redirects: 2) }
      .to raise_error(described_class::TooManyRedirectsError)
    expect(a_request(:get, public_url)).to have_been_made.times(3)
  end

  it "raises errors that callers rescuing HTTParty::Error already handle" do
    expect(described_class::BlockedUrlError.ancestors).to include(HTTParty::Error)
    expect(described_class::TooManyRedirectsError.ancestors).to include(HTTParty::Error)
  end
end
