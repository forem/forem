# frozen_string_literal: true

RSpec.describe Slack::Notifier::PayloadMiddleware::Channels do
  it "leaves string channels alone" do
    subject = described_class.new(:notifier)
    payload = { text: "hello", channel: "hodor" }

    expect(subject.call(payload)).to eq text: "hello", channel: "hodor"
  end

  it "splits payload into multiple if given an array of channels" do
    subject = described_class.new(:notifier)
    payload = { text: "hello", channel: %w[foo hodor] }

    expect(subject.call(payload)).to eq [
      { text: "hello", channel: "foo" },
      { text: "hello", channel: "hodor" }
    ]
  end
end
