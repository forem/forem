require "rails_helper"

RSpec.describe Podcasts::GetMediaUrl, type: :service do
  let(:https_url) { "https://hello.example.com/" }
  let(:http_url) { "http://hello.example.com/" }
  let(:options) { { timeout: described_class::TIMEOUT } }

  before do
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    allow(Addrinfo).to receive(:getaddrinfo)
      .with("hello.example.com", nil, nil, :STREAM)
      .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])
  end

  it "https, reachable" do
    stub_request(:head, https_url).to_return(status: 200)
    result = described_class.call(https_url)

    expect(result).to have_attributes(https: true, reachable: true, url: https_url)
  end

  it "normalizes url" do
    url = "https://hello.example.com/hi%20there.mp3"
    stub_request(:head, url).to_return(status: 200)
    result = described_class.call(url)

    expect(result).to have_attributes(https: true, reachable: true, url: url)
  end

  it "https, unreachable" do
    stub_request(:head, https_url).to_return(status: 404)
    result = described_class.call(https_url)

    expect(result).to have_attributes(https: true, reachable: false, url: https_url)
  end

  it "http, https reachable" do
    stub_request(:head, https_url).to_return(status: 200)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: true, reachable: true, url: https_url)
  end

  it "http, https unreachable, http reachable" do
    httparty_result = double
    allow(httparty_result).to receive(:code).and_return(200)
    allow(SafeHttp).to receive(:head).with(http_url, **options).and_return(httparty_result)
    allow(SafeHttp).to receive(:head).with(https_url, **options).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: true, url: http_url)
  end

  it "http, https unreachable" do
    allow(SafeHttp).to receive(:head).with(https_url, **options).and_raise(Errno::ECONNREFUSED)
    allow(SafeHttp).to receive(:head).with(http_url, **options).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "http, https unreachable with other exception" do
    allow(SafeHttp).to receive(:head).with(https_url, **options).and_raise(Errno::EINVAL)
    allow(SafeHttp).to receive(:head).with(http_url, **options).and_raise(Errno::EINVAL)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "http, https unreachable with invalid url exception" do
    allow(SafeHttp).to receive(:head).with(https_url, **options).and_raise(URI::InvalidURIError)
    allow(SafeHttp).to receive(:head).with(http_url, **options).and_raise(URI::InvalidURIError)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "http, https unreachable with openssl error" do
    httparty_result = instance_double(HTTParty::Response, code: 200)
    allow(SafeHttp).to receive(:head).with(https_url, **options).and_raise(OpenSSL::SSL::SSLError)
    allow(SafeHttp).to receive(:head).with(http_url, **options).and_return(httparty_result)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: true, url: http_url)
  end

  it "marks unreachable with addressable invalid url exception" do
    allow(SafeHttp).to receive(:head).with(https_url, **options).and_raise(Addressable::URI::InvalidURIError)
    allow(SafeHttp).to receive(:head).with(http_url, **options).and_raise(Addressable::URI::InvalidURIError)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "marks socket errors as invalid url exception" do
    allow(SafeHttp).to receive(:head).with(https_url, **options).and_raise(SocketError)
    allow(SafeHttp).to receive(:head).with(http_url, **options).and_raise(SocketError)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  describe "SSRF protection" do
    [
      "http://169.254.169.254/latest/meta-data/",
      "http://127.0.0.1:6379/",
      "http://10.0.0.5/internal.mp3",
      "http://[::1]/internal.mp3",
    ].each do |internal_url|
      it "blocks #{internal_url} without issuing an HTTP request" do
        stub_request(:head, internal_url).to_return(status: 200)
        stub_request(:head, internal_url.sub("http:", "https:")).to_return(status: 200)

        result = described_class.call(internal_url)

        expect(result).to have_attributes(https: false, reachable: false, url: internal_url)
        expect(a_request(:head, internal_url)).not_to have_been_made
        expect(a_request(:head, internal_url.sub("http:", "https:"))).not_to have_been_made
      end
    end

    it "blocks a redirect from a public host to an internal address" do
      internal_url = "http://169.254.169.254/latest/meta-data/"
      stub_request(:head, https_url).to_return(status: 302, headers: { "Location" => internal_url })
      stub_request(:head, internal_url).to_return(status: 200)

      result = described_class.call(https_url)

      expect(result).to have_attributes(https: true, reachable: false, url: https_url)
      expect(a_request(:head, internal_url)).not_to have_been_made
    end

    it "blocks a hostname resolving to a private IP address" do
      private_host_url = "https://internal.example.com/audio.mp3"
      allow(Addrinfo).to receive(:getaddrinfo)
        .with("internal.example.com", nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "10.1.2.3")])
      stub_request(:head, private_host_url).to_return(status: 200)

      result = described_class.call(private_host_url)

      expect(result).to have_attributes(https: true, reachable: false, url: private_host_url)
      expect(a_request(:head, private_host_url)).not_to have_been_made
    end
  end
end
