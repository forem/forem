require "rails_helper"

RSpec.describe Webhook::DispatchEventJob, type: :job do
  include_examples "#enqueues_job", "webhook_dispatch_events", "https://example.com", ""

  describe "#perform_now" do
    let(:article) { create(:article) }
    let(:payload) { Webhook::PayloadAdapter.new(article).hash }
    let(:json) { Webhook::Event.new(event_type: "article_updated", payload: payload).to_json }
    let(:url) { Faker::Internet.url }

    it "posts an event" do
      client = double
      allow(client).to receive(:post)
      described_class.perform_now(endpoint_url: url, payload: json, client: client)
      expect(client).to have_received(:post).once.
        with(Addressable::URI.parse(url), headers: { "Content-Type" => "application/json" },
                                          body: json,
                                          timeout: 10)
    end

    it "doesn't fail" do
      stub_request(:post, url).to_return(status: 200)
      described_class.perform_now(endpoint_url: url, payload: json)
    end
  end
end
