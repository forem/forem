require "rails_helper"

RSpec.describe AiAssistantReferral do
  describe ".referrer_for" do
    it "returns a referrer URL for a known assistant domain" do
      expect(described_class.referrer_for("chatgpt.com")).to eq("https://chatgpt.com/")
    end

    it "normalizes case, scheme, www and trailing slash" do
      expect(described_class.referrer_for(" HTTPS://www.Perplexity.ai/ ")).to eq("https://perplexity.ai/")
    end

    it "returns nil for an unknown source" do
      expect(described_class.referrer_for("newsletter")).to be_nil
      expect(described_class.referrer_for("evil.example.com")).to be_nil
    end

    it "returns nil for a blank source" do
      expect(described_class.referrer_for(nil)).to be_nil
      expect(described_class.referrer_for("")).to be_nil
    end
  end
end
