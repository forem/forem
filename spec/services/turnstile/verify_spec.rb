require "rails_helper"

RSpec.describe Turnstile::Verify do
  subject(:verified) { described_class.call(token: token, hostname: "forem.test", action: "signup") }

  let(:token) { "challenge-token" }
  let(:result) { { success: true, hostname: "forem.test", action: "signup" } }
  let!(:verification) do
    stub_request(:post, described_class::ENDPOINT)
      .with(body: { secret: "turnstile-secret", response: "challenge-token" })
      .to_return(status: 200, body: result.to_json)
  end

  before do
    allow(Settings::Authentication).to receive_messages(turnstile_site_key: "turnstile-site",
                                                        turnstile_secret_key: "turnstile-secret")
  end

  it { is_expected.to be(true) }

  [nil, "", " ", [], {}, "x" * 2049].each do |invalid_token|
    context "with invalid token #{invalid_token.inspect.truncate(40)}" do
      let(:token) { invalid_token }

      it "rejects the token without contacting Cloudflare", :aggregate_failures do
        expect(verified).to be(false)
        expect(verification).not_to have_been_requested
      end
    end
  end

  [{ success: false }, { success: "true", hostname: "forem.test" },
   { success: true }, { success: true, hostname: "other.example" }, [], nil].each do |invalid_result|
    context "with response #{invalid_result.inspect}" do
      let(:result) { invalid_result }

      it { is_expected.to be(false) }
    end
  end

  %i[turnstile_site_key turnstile_secret_key].each do |key|
    it "fails closed without #{key}", :aggregate_failures do
      allow(Settings::Authentication).to receive(key).and_return("")

      expect(verified).to be(false)
      expect(verification).not_to have_been_requested
    end
  end

  it "rejects an unsuccessful HTTP status" do
    stub_request(:post, described_class::ENDPOINT).to_return(status: 503, body: result.to_json)
    expect(verified).to be(false)
  end

  it "rejects invalid JSON" do
    stub_request(:post, described_class::ENDPOINT).to_return(status: 200, body: "not json")
    expect(verified).to be(false)
  end

  it "fails closed when the request times out" do
    stub_request(:post, described_class::ENDPOINT).to_timeout
    expect(verified).to be(false)
  end

  it "fails closed when Cloudflare is unreachable" do
    stub_request(:post, described_class::ENDPOINT).to_raise(SocketError)
    expect(verified).to be(false)
  end

  it "does not follow redirects containing the secret" do
    stub_request(:post, described_class::ENDPOINT)
      .to_return(status: 302, headers: { "Location" => "https://other.example/verify" })
    expect(verified).to be(false)
  end
end
