require "rails_helper"

RSpec.describe Webhook::Event, type: :model do
  let(:article) { create(:article) }
  let(:payload) { Webhook::PayloadAdapter.new(article).hash }

  describe "validations" do
    it "raises an exception with a unknown event type" do
      expect do
        described_class.new(event_type: "cool_event")
      end.to raise_error(Webhook::InvalidEvent)
    end
  end

  describe "#as_json" do
    it "provides correct json (sample)" do
      event = described_class.new(event_type: "article_created", payload: { title: "Hello, world" })
      hash = event.as_json

      attributes = hash[:data][:attributes]

      expect(attributes[:event_type]).to eq("article_created")
      expect(attributes[:timestamp]).to be_truthy
      expect(attributes[:payload][:title]).to eq("Hello, world")
    end

    it "provides correct json including article" do
      event = described_class.new(event_type: "article_updated", payload: payload)
      hash = event.as_json
      attributes = hash[:data][:attributes]
      expect(attributes[:event_type]).to eq("article_updated")
      expect(attributes[:payload][:data][:attributes][:title]).to eq(article.title)
    end

    it "provides an event_id dependent on time" do
      event1 = described_class.new(event_type: "article_updated", payload: payload)
      event1_id = event1.as_json.dig(:data, :id)

      event2 = nil
      Timecop.freeze(1.month.ago) do
        event2 = described_class.new(event_type: "article_updated", payload: payload)
      end
      event2_id = event2.as_json.dig(:data, :id)

      expect(event2_id < event1_id).to be(true)
    end
  end

  describe "#to_json" do
    it "provides correct json including article" do
      event = described_class.new(event_type: "article_updated", payload: payload)
      json = event.to_json
      hash = JSON.parse(json)
      attributes = hash["data"]["attributes"]

      expect(attributes["event_type"]).to eq("article_updated")
      expect(attributes["payload"]["data"]["attributes"]["title"]).to eq(article.title)
    end
  end
end
