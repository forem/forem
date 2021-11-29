require "rails_helper"

RSpec.describe Settings::Community do
  describe "validating community name" do
    it "does not allow '<' nor '>' character" do
      expect do
        described_class.community_name = "<Hiya"
      end.to raise_error(/may not include the "<" nor ">"/)

      expect do
        described_class.community_name = "Bya>"
      end.to raise_error(/may not include the "<" nor ">"/)

      expect do
        described_class.community_name = "Hello Folks"
      end.not_to raise_error
    end
  end

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
