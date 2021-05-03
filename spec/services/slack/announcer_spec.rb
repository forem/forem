require "rails_helper"

RSpec.describe Slack::Announcer, type: :service do
  it "does not call the client if any of the params is blank" do
    allow(SlackClient).to receive(:ping)

    params = {
      message: "something",
      channel: nil,
      username: "",
      icon_emoji: ":o:"
    }
    expect(described_class.call(**params)).to be_nil
    expect(SlackClient).not_to have_received(:ping)
  end

  it "calls the client if all params are given" do
    allow(SlackClient).to receive(:ping)

    message = "hello there"
    params = {
      message: message,
      channel: "#help",
      username: "bob",
      icon_emoji: ":o:"
    }

    described_class.call(**params)

    expect(SlackClient).to have_received(:ping)
      .with(message, params.reject { |k| k == :message })
      .once
  end
end
