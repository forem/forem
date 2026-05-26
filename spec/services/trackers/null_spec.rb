require "rails_helper"

RSpec.describe Trackers::Null do
  subject(:adapter) { described_class.new }

  describe "#track" do
    it "returns nil and does nothing" do
      expect(adapter.track(event_name: "x", user_ids: [1], properties: { a: 1 })).to be_nil
    end

    it "accepts an optional timestamp" do
      expect do
        adapter.track(event_name: "x", user_ids: [1], properties: {}, timestamp: Time.current)
      end.not_to raise_error
    end
  end

  describe "#enabled?" do
    it "is always enabled" do
      expect(adapter.enabled?).to be true
    end
  end

  it "inherits from Trackers::Base" do
    expect(described_class.ancestors).to include(Trackers::Base)
  end
end
