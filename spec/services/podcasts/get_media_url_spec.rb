require "rails_helper"

RSpec.describe Podcasts::GetMediaUrl do
  let(:https_url) { "https://hello.example.com" }
  let(:http_url) { "http://hello.example.com" }

  it "https, reachable" do
    stub_request(:head, https_url).to_return(status: 200)
    result = described_class.call(https_url)
    expect(result.https).to be true
    expect(result.reachable).to be true
    expect(result.url).to eq(https_url)
  end

  it "https, unrechable" do
    stub_request(:head, https_url).to_return(status: 404)
    result = described_class.call(https_url)
    expect(result.https).to be true
    expect(result.reachable).to be false
    expect(result.url).to eq(https_url)
  end

  it "http, https reachable" do
    stub_request(:head, https_url).to_return(status: 200)
    result = described_class.call(http_url)
    expect(result.https).to be true
    expect(result.reachable).to be true
    expect(result.url).to eq(https_url)
  end

  it "http, https unreachable, http reachable" do
    httparty_result = double
    allow(httparty_result).to receive(:code).and_return(200)
    allow(HTTParty).to receive(:head).with(http_url).and_return(httparty_result)
    allow(HTTParty).to receive(:head).with(https_url).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)
    expect(result.https).to be false
    expect(result.reachable).to be true
    expect(result.url).to eq(http_url)
  end

  it "http, https unreachable" do
    allow(HTTParty).to receive(:head).with(https_url).and_raise(Errno::ECONNREFUSED)
    allow(HTTParty).to receive(:head).with(http_url).and_raise(Errno::ECONNREFUSED)
    result = described_class.call(http_url)
    expect(result.https).to be false
    expect(result.reachable).to be false
    expect(result.url).to eq(http_url)
  end
end
