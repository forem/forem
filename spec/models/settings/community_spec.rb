require "rails_helper"

RSpec.describe Settings::Community do
  describe "validating emojis strings" do
    it "allows emoji-only strings" do
      expect do
        described_class.community_emoji = "💯"
      end.not_to raise_error
    end

    it "rejects non emoji-only strings" do
      expect do
        described_class.community_emoji = "abc"
      end.to raise_error(/contains non-emoji characters or invalid emoji/)
    end
  end
end
