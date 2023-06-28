require "rails_helper"

RSpec.describe Slack::WorkflowWebhook, type: :service do
  it "does nothing when missing SLACK_WORKFLOW_WEBHOOK_URL" do
    allow(ENV).to receive(:[]).with("SLACK_WORKFLOW_WEBHOOK_URL").and_return(nil)
    allow(HTTParty).to receive(:post).and_call_original

    described_class.call("test")
    expect(HTTParty).not_to have_received(:post)
  end

  it "send a post request to the webhook url" do
    ENV["SLACK_WORKFLOW_WEBHOOK_URL"] = "https://example.com"
    allow(HTTParty).to receive(:post).and_return(true)

    described_class.call("test")
    expect(HTTParty).to have_received(:post).with(
      "https://example.com",
      body: { message: "test" }.to_json,
      headers: { "Content-Type" => "application/json" },
    )
    ENV["SLACK_WORKFLOW_WEBHOOK_USERNAME"] = nil
  end
end
