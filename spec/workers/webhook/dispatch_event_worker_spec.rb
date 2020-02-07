require "rails_helper"

RSpec.describe Webhook::DispatchEventWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "medium_priority", ["https://example.com", {}.to_json]

  describe "#perform_now" do
    let(:article) { create(:article) }
    let(:payload) { Webhook::PayloadAdapter.new(article).hash }
    let(:json) { Webhook::Event.new(event_type: "article_updated", payload: payload).to_json }
    let(:url) { Faker::Internet.url }
    let(:client) { HTTParty }

    it "posts an event" do
      allow(client).to receive(:post)
      worker.perform(url, json)
      expect(client).to have_received(:post).once.
        with(Addressable::URI.parse(url), headers: { "Content-Type" => "application/json" },
                                          body: json,
                                          timeout: 10)
    end

    it "doesn't fail" do
      stub_request(:post, url).to_return(status: 200)
      worker.perform(url, json)
    end
  end
end
