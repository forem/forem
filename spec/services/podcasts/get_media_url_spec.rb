require "rails_helper"

RSpec.describe Podcasts::GetMediaUrl, type: :service do
  let(:https_url) { "https://hello.example.com/" }
  let(:http_url) { "http://hello.example.com/" }

  xit "https, reachable" do
    stub_request(:head, https_url).to_return(status: 200)
    result = described_class.call(https_url)
    expect(result.https).to be true
    expect(result.reachable).to be true
    expect(result.url).to eq(https_url)
  end

  xit "normalizes url" do
    url = "https://hello.example.com/hi%20there.mp3"
    stub_request(:head, url).to_return(status: 200)
    result = described_class.call(url)
    expect(result.https).to be true
    expect(result.reachable).to be true
    expect(result.url).to eq(url)
  end

  xit "https, unrechable" do
    stub_request(:head, https_url).to_return(status: 404)
    result = described_class.call(https_url)
    expect(result.https).to be true
    expect(result.reachable).to be false
    expect(result.url).to eq(https_url)
  end

  xit "http, https reachable" do
    stub_request(:head, https_url).to_return(status: 200)
    result = described_class.call(http_url)
    expect(result.https).to be true
    expect(result.reachable).to be true
    expect(result.url).to eq(https_url)
  end

  xit "http, https unreachable, http reachable" do
    httparty_result = double
    allow(httparty_result).to receive(:code).and_return(200)
    allow(HTTParty).to receive(:head).with(http_url).and_return(httparty_result)
    allow(HTTParty).to receive(:head).with(https_url).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)
    expect(result.https).to be false
    expect(result.reachable).to be true
    expect(result.url).to eq(http_url)
  end

  xit "http, https unreachable" do
    allow(HTTParty).to receive(:head).with(https_url).and_raise(Errno::ECONNREFUSED)
    allow(HTTParty).to receive(:head).with(http_url).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)
    expect(result.https).to be false
    expect(result.reachable).to be false
    expect(result.url).to eq(http_url)
  end

  xit "http, https unreachable with other exception" do
    allow(HTTParty).to receive(:head).with(https_url).and_raise(Errno::EINVAL)
    allow(HTTParty).to receive(:head).with(http_url).and_raise(Errno::EINVAL)
    result = described_class.call(http_url)
    expect(result.https).to be false
    expect(result.reachable).to be false
    expect(result.url).to eq(http_url)
  end

  xit "http, https unreachable with invalid url exception" do
    allow(HTTParty).to receive(:head).with(https_url).and_raise(URI::InvalidURIError)
    allow(HTTParty).to receive(:head).with(http_url).and_raise(URI::InvalidURIError)
    result = described_class.call(http_url)
    expect(result.https).to be false
    expect(result.reachable).to be false
    expect(result.url).to eq(http_url)
  end

  xit "marks unreachable with addressable invalid url exception" do
    allow(HTTParty).to receive(:head).with(https_url).and_raise(Addressable::URI::InvalidURIError)
    allow(HTTParty).to receive(:head).with(http_url).and_raise(Addressable::URI::InvalidURIError)
    result = described_class.call(http_url)
    expect(result.https).to be false
    expect(result.reachable).to be false
    expect(result.url).to eq(http_url)
  end
end
