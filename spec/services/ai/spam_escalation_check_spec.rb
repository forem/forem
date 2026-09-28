require "rails_helper"

RSpec.describe Ai::SpamEscalationCheck do
  subject(:check) { described_class.new(text: "DM me on Telegram @seller for verified accounts", content: article) }

  let(:article) { create(:article) }

  context "when :spam_escalation is set to Jev" do
    before { enable_jev_for(:spam_escalation) }

    it "escalates when any question is at or above the threshold" do
      stub_jev(offplatform_contact: described_class::THRESHOLD)

      expect(check.escalate?).to be(true)
    end

    it "does not escalate when every answer is below the threshold" do
      stub_jev(spam: 0.1, offplatform_contact: 0.1)

      expect(check.escalate?).to be(false)
    end

    it "sends the truncated text as the state" do
      requests = stub_jev
      described_class.new(text: "a" * 5_000, content: article).escalate?

      expect(requests.first[:state]).to eq(content: "a" * described_class::MAX_TEXT_LENGTH)
      expect(requests.first[:questions].keys).to eq(%i[spam offplatform_contact])
    end

    it "does not escalate when the TypeSafe API fails" do
      client = instance_double(Ai::TypeSafe::Client)
      allow(Ai::TypeSafe::Client).to receive(:new).and_return(client)
      allow(client).to receive(:evaluate).and_raise(Ai::TypeSafe::Client::Error.new("boom", status_code: 400))

      expect(check.escalate?).to be(false)
    end

    it "logs the call to AiAudit under this check" do
      allow(Ai::TypeSafe::Client).to receive(:post).and_return(
        instance_double(HTTParty::Response, success?: true, code: 200, parsed_response: {
                          "model" => "jev-1.13.0",
                          "answers" => { "spam" => { "type" => "noul", "noul" => 0.1 },
                                         "offplatform_contact" => { "type" => "noul", "noul" => 0.1 } },
                          "usage" => { "input_tokens" => 42, "output_tokens" => 0 }
                        }),
      )

      expect { check.escalate? }.to change(AiAudit, :count).by(1)
      expect(AiAudit.last).to have_attributes(ai_model: "jev-1.13.0", wrapper_object_class: described_class.name,
                                              wrapper_object_version: described_class::VERSION,
                                              affected_content: article, prompt_token_count: 42)
    end
  end

  it "does not escalate or call Jev when :spam_escalation is off, even with a TypeSafe key" do
    stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", "test-typesafe-key")
    allow(Ai::TypeSafe::Client).to receive(:new)

    expect(check.escalate?).to be(false)
    expect(Ai::TypeSafe::Client).not_to have_received(:new)
  end

  it "does not escalate when Jev is selected but the TypeSafe key is missing" do
    enable_jev_for(:spam_escalation)
    stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", nil)
    allow(Ai::TypeSafe::Client).to receive(:new)

    expect(check.escalate?).to be(false)
    expect(Ai::TypeSafe::Client).not_to have_received(:new)
  end
end
