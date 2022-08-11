require "rails_helper"

RSpec.describe Podcasts::GetMediaUrl, type: :service do
  let(:https_url) { "https://hello.example.com/" }
  let(:http_url) { "http://hello.example.com/" }
  let(:options) { { timeout: described_class::TIMEOUT } }

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
    allow(HTTParty).to receive(:head).with(http_url, options).and_return(httparty_result)
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: true, url: http_url)
  end

  it "http, https unreachable" do
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(Errno::ECONNREFUSED)
    allow(HTTParty).to receive(:head).with(http_url, options).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "http, https unreachable with other exception" do
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(Errno::EINVAL)
    allow(HTTParty).to receive(:head).with(http_url, options).and_raise(Errno::EINVAL)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "http, https unreachable with invalid url exception" do
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(URI::InvalidURIError)
    allow(HTTParty).to receive(:head).with(http_url, options).and_raise(URI::InvalidURIError)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "http, https unreachable with openssl error" do
    httparty_result = instance_double(HTTParty::Response, code: 200)
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(OpenSSL::SSL::SSLError)
    allow(HTTParty).to receive(:head).with(http_url, options).and_return(httparty_result)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: true, url: http_url)
  end

  it "marks unreachable with addressable invalid url exception" do
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(Addressable::URI::InvalidURIError)
    allow(HTTParty).to receive(:head).with(http_url, options).and_raise(Addressable::URI::InvalidURIError)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end

  it "marks socket errors as invalid url exception" do
    allow(HTTParty).to receive(:head).with(https_url, options).and_raise(SocketError)
    allow(HTTParty).to receive(:head).with(http_url, options).and_raise(SocketError)
    result = described_class.call(http_url)

    expect(result).to have_attributes(https: false, reachable: false, url: http_url)
  end
end
