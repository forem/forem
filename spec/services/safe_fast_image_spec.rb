require "rails_helper"

RSpec.describe SafeFastImage, type: :service do
  let(:public_url) { "https://images.example/photo.png" }
  let(:other_public_url) { "https://cdn.example/anim.gif" }
  let(:metadata_url) { "http://169.254.169.254/latest/meta-data/" }

  # Minimal valid 2x3 PNG header (signature + IHDR chunk)
  let(:png_bytes) do
    "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x02\x00\x00\x00\x03\x08\x02\x00\x00\x00".b
  end

  # Minimal valid 1x1 GIF89a image
  let(:gif_bytes) do
    "GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xFF\xFF\xFF!" \
    "\xF9\x04\x00\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;".b
  end

  def resolve(host, ip)
    allow(Addrinfo).to receive(:getaddrinfo)
      .with(host, nil, nil, :STREAM)
      .and_return([instance_double(Addrinfo, ip_address: ip)])
  end

  before do
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    resolve("images.example", "203.0.113.10")
    resolve("cdn.example", "203.0.113.11")
  end

  it "returns size and type for a public image in a single request" do
    stub_request(:get, public_url).to_return(status: 200, body: png_bytes)

    image = described_class.new(public_url)

    expect(image.size).to eq([2, 3])
    expect(image.type).to eq(:png)
    expect(a_request(:get, public_url)).to have_been_made.once
  end

  it "follows public-to-public redirects without mixing redirect bodies" do
    stub_request(:get, public_url)
      .to_return(status: 302, headers: { "Location" => other_public_url }, body: "<html>Moved</html>")
    stub_request(:get, other_public_url).to_return(status: 200, body: gif_bytes)

    image = described_class.new(public_url)

    expect(image.size).to eq([1, 1])
    expect(image.type).to eq(:gif)
  end

  [
    "http://169.254.169.254/latest/meta-data/",
    "http://127.0.0.1:6379/",
    "http://10.0.0.5/internal.png",
    "http://[::1]/secret.png",
    "file:///etc/passwd",
    "/etc/passwd",
  ].each do |blocked_url|
    it "blocks #{blocked_url} without issuing an HTTP request" do
      stub_request(:get, blocked_url) if blocked_url.start_with?("http")

      image = described_class.new(blocked_url)

      expect(image.size).to be_nil
      expect(image.type).to be_nil
      expect(a_request(:get, blocked_url)).not_to have_been_made if blocked_url.start_with?("http")
    end
  end

  it "blocks a hostname that resolves to a private IP" do
    resolve("internal.example", "10.1.2.3")
    stub_request(:get, "https://internal.example/image.png")

    expect(described_class.size("https://internal.example/image.png")).to be_nil
    expect(a_request(:get, "https://internal.example/image.png")).not_to have_been_made
  end

  it "blocks a public URL redirecting to an internal address" do
    stub_request(:get, public_url).to_return(status: 302, headers: { "Location" => metadata_url })
    stub_request(:get, metadata_url).to_return(status: 200, body: png_bytes)

    expect(described_class.size(public_url)).to be_nil
    expect(a_request(:get, metadata_url)).not_to have_been_made
  end

  it "returns nil for non-2xx responses and aborts reading oversized error or redirect bodies" do
    stub_request(:get, public_url).to_return(status: 404, body: png_bytes)
    expect(described_class.size(public_url)).to be_nil

    stub_request(:get, public_url)
      .to_return(status: 302, headers: { "Location" => other_public_url }, body: "x" * 70_000)
    stub_request(:get, other_public_url).to_return(status: 200, body: gif_bytes)

    expect(described_class.size(public_url)).to be_nil
    expect(a_request(:get, other_public_url)).not_to have_been_made
  end

  it "never logs URL userinfo or query parameters on rejected requests" do
    allow(Rails.logger).to receive(:warn)
    secret_url = "ftp://user:secret@example.com/private.png?token=signed123"

    expect(described_class.size(secret_url)).to be_nil
    expect(Rails.logger).to have_received(:warn)
      .with("[SafeFastImage] Rejected image request (SafeHttp::BlockedUrlError)")
  end

  it "aborts and returns nil when the overall wall-clock deadline expires" do
    now = 100.0
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(now, now + 15.0)
    allow(SafeHttp).to receive(:get) do |_url, **opts|
      opts[:validate_url].call(public_url)
      raise "should not continue past expired deadline"
    end

    image = described_class.new(public_url, timeout: 10)

    expect(image.size).to be_nil
    expect(image.type).to be_nil
  end

  it "disables implicit environment proxies on outbound requests" do
    allow(SafeHttp).to receive(:get).and_call_original
    stub_request(:get, public_url).to_return(status: 200, body: png_bytes)

    described_class.size(public_url)

    expect(SafeHttp).to have_received(:get).with(public_url, hash_including(http_proxyaddr: nil))
  end

  it "inspects verified local files via .from_file" do
    fixture_path = Rails.root.join("spec/support/fixtures/images/image1.jpeg").to_s

    image = described_class.from_file(fixture_path)

    expect(image.size).to be_an(Array)
    expect(image.type).to eq(:jpeg)
  end
end
