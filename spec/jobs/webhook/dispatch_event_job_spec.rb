require "rails_helper"

RSpec.describe Webhook::DispatchEventJob, type: :job do
  include_examples "#enqueues_job", "dispatch_webhook_events", "https://example.com", ""

  describe "#perform_now" do
    let(:article) { create(:article) }
    let(:json) { Webhook::Event.new(event_type: "article_updated", payload: article.webhook_data).to_json }
    let(:url) { Faker::Internet.url }

    it "posts an event" do
      stub_request(:post, url).to_return(status: 200)
      client = double
      allow(client).to receive(:post)
      described_class.perform_now(endpoint_url: url, payload: json, client: client)
      expect(client).to have_received(:post).once.with(URI.parse(url), headers: { "Content-Type" => "application/json" }, body: json)
    end
  end
end
