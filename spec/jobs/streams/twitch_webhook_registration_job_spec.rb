require "rails_helper"

RSpec.describe Streams::TwitchWebhookRegistrationJob, type: :job do
  let(:user) { create(:user, twitch_username: "test-username") }

  let(:service) { double }

  before do
    allow(service).to receive(:call)
  end

  context "when the user does NOT have a twitch username present" do
    let(:user) { create(:user) }

    it "noops" do
      described_class.perform_now(user.id, service)

      expect(service).not_to have_received(:call)
    end
  end

  it "noops when the id passed does not belong to a user" do
    described_class.perform_now(987_654_321, service)

    expect(service).not_to have_received(:call)
  end

  it "registers for webhooks" do
    described_class.perform_now(user.id, service)

    expect(service).to have_received(:call).with(user)
  end
end
