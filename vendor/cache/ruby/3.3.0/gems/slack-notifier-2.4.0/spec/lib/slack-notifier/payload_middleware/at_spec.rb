# frozen_string_literal: true

RSpec.describe Slack::Notifier::PayloadMiddleware::At do
  it "can handle array at" do
    subject = described_class.new(:notifier)
    payload = { text: "hello", at: %i[john ken here] }

    expect(subject.call(payload)).to eq text: "<@john> <@ken> <!here> hello"
  end

  it "can handle single at option" do
    subject = described_class.new(:notifier)
    payload = { text: "hello", at: :alice }

    expect(subject.call(payload)).to eq text: "<@alice> hello"
  end

  it "generates :text in payload if given :at & no :text" do
    subject = described_class.new(:notifier)
    input_payload  = { at: [:here], attachments: [{ text: "hello" }] }
    output_payload = { text: "<!here> ", attachments: [{ text: "hello" }] }

    expect(subject.call(input_payload)).to eq output_payload
  end
end
