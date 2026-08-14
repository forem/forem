require "rails_helper"

RSpec.describe Trackers::Base do
  describe "#track" do
    it "raises NotImplementedError" do
      expect do
        described_class.new.track(event_name: "x", user_ids: [1], properties: {})
      end.to raise_error(NotImplementedError)
    end
  end

  describe "#enabled?" do
    it "returns true by default" do
      expect(described_class.new.enabled?).to be true
    end
  end
end
