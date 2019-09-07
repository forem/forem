require "rails_helper"

RSpec.describe Webhook::Event, type: :model do
  let(:article) { create(:article) }
  let!(:payload) { Webhook::PayloadAdapter.new(article).hash }

  it "rases an exception" do
    expect do
      described_class.new(event_type: "cool_event")
    end.to raise_error(Webhook::InvalidEvent)
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
