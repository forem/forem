require "rails_helper"

RSpec.describe Turnstile::Verify do
  subject(:verified) { described_class.call(token: "challenge-token", hostname: "forem.test", action: action) }

  let(:action) { "signup" }
  let(:returned_action) { "signup" }

  before do
    allow(Settings::Authentication).to receive_messages(turnstile_site_key: "site-key",
                                                        turnstile_secret_key: "secret-key")
    stub_request(:post, described_class::ENDPOINT)
      .to_return(body: { success: true, hostname: "forem.test", action: returned_action }.to_json)
  end

  it { is_expected.to be(true) }

  context "when a token belongs to another form" do
    let(:returned_action) { "abuse_report" }

    it { is_expected.to be(false) }
  end

  context "when the response has no action" do
    let(:returned_action) { nil }

    it { is_expected.to be(false) }
  end

  context "when no expected action was provided" do
    let(:action) { nil }
    let(:returned_action) { action }

    it "rejects the action without contacting Cloudflare", :aggregate_failures do
      expect(verified).to be(false)
      expect(WebMock).not_to have_requested(:post, described_class::ENDPOINT)
    end
  end

  ["", " ", [], {}, 1].each do |invalid_action|
    context "with invalid expected action #{invalid_action.inspect}" do
      let(:action) { invalid_action }
      let(:returned_action) { action }

      it "rejects the action without contacting Cloudflare", :aggregate_failures do
        expect(verified).to be(false)
        expect(WebMock).not_to have_requested(:post, described_class::ENDPOINT)
      end
    end
  end

  [EOFError, IOError].each do |error|
    it "rejects an interrupted connection raising #{error}" do
      stub_request(:post, described_class::ENDPOINT).to_raise(error)
      expect(verified).to be(false)
    end
  end
end
