require "rails_helper"

RSpec.describe Ai::SpamEscalationCheck do
  subject(:check) { described_class.new(text: "DM me on Telegram @seller for verified accounts", content: article) }

  let(:article) { create(:article) }
  let(:answers) { { "spam" => { "noul" => 0.1 }, "offplatform_contact" => { "noul" => 0.1 } } }
  let(:response) do
    instance_double(HTTParty::Response, success?: true, code: 200,
                                        parsed_response: { "model" => "jev-1.13.0", "answers" => answers,
                                                           "usage" => { "input_tokens" => 42 } })
  end

  before do
    stub_const("Ai::Jev::DEFAULT_KEY", "test_key")
    allow(Ai::Jev).to receive(:post).and_return(response)
  end

  it "escalates when any question is at or above the threshold" do
    answers["offplatform_contact"]["noul"] = described_class::THRESHOLD
    expect(check.escalate?).to be(true)
  end

  it "does not escalate when every answer is below the threshold" do
    expect(check.escalate?).to be(false)
  end

  it "logs the call to AiAudit" do
    expect { check.escalate? }.to change(AiAudit, :count).by(1)
    expect(AiAudit.last).to have_attributes(ai_model: "jev-1.13.0", wrapper_object_class: described_class.name,
                                            affected_content: article, prompt_token_count: 42)
  end

  it "does not escalate or call Jev without an API key" do
    stub_const("Ai::Jev::DEFAULT_KEY", nil)
    expect(check.escalate?).to be(false)
    expect(Ai::Jev).not_to have_received(:post)
  end

  it "does not escalate when the Jev API fails" do
    allow(Ai::Jev).to receive(:post)
      .and_return(instance_double(HTTParty::Response, success?: false, code: 529, parsed_response: {}))
    expect(check.escalate?).to be(false)
  end
end
