require "rails_helper"

RSpec.describe HCaptcha::Verify do
  subject(:verified) { described_class.call(token: token) }

  let(:token) { "challenge-token" }
  let(:result) { { success: true } }

  before do
    allow(Settings::Authentication).to receive_messages(hcaptcha_site_key: "hcaptcha-site",
                                                        hcaptcha_secret_key: "hcaptcha-secret")
    stub_request(:post, "https://api.hcaptcha.com/siteverify")
      .with(body: { secret: "hcaptcha-secret", response: "challenge-token", sitekey: "hcaptcha-site" })
      .to_return(status: 200, body: result.to_json)
  end

  it "verifies against the configured sitekey" do
    expect(verified).to be(true)
  end

  [nil, "", " ", [], {}].each do |invalid_token|
    context "with token #{invalid_token.inspect}" do
      let(:token) { invalid_token }

      it { is_expected.to be(false) }
    end
  end

  [{ success: false }, { success: "true" }, {}, [], nil].each do |invalid_result|
    context "with response #{invalid_result.inspect}" do
      let(:result) { invalid_result }

      it { is_expected.to be(false) }
    end
  end

  %i[hcaptcha_site_key hcaptcha_secret_key].each do |key|
    it "fails closed without #{key}" do
      allow(Settings::Authentication).to receive(key).and_return(nil)
      expect(verified).to be(false)
    end
  end

  it "rejects an unsuccessful HTTP status" do
    stub_request(:post, "https://api.hcaptcha.com/siteverify").to_return(status: 503, body: result.to_json)
    expect(verified).to be(false)
  end

  it "rejects malformed JSON" do
    stub_request(:post, "https://api.hcaptcha.com/siteverify").to_return(body: "not json")
    expect(verified).to be(false)
  end

  it "fails closed when the verification request times out" do
    stub_request(:post, "https://api.hcaptcha.com/siteverify").to_timeout
    expect(verified).to be(false)
  end

  it "fails closed when hCaptcha is unreachable" do
    stub_request(:post, "https://api.hcaptcha.com/siteverify").to_raise(SocketError)
    expect(verified).to be(false)
  end

  it "does not follow redirects carrying the secret" do
    stub_request(:post, "https://api.hcaptcha.com/siteverify")
      .to_return(status: 302, headers: { "Location" => "https://other.example/verify" })
    expect(verified).to be(false)
  end
end
