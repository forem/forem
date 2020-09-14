require "rails_helper"

RSpec.describe SiteConfig, type: :model do
  describe ".local?" do
    it "returns true if the .app_domain points to localhost" do
      allow(described_class).to receive(:app_domain).and_return("localhost:3000")

      expect(described_class.local?).to be(true)
    end

    it "returns false if the .app_domain points to a regular domain" do
      allow(described_class).to receive(:app_domain).and_return("forem.dev")

      expect(described_class.local?).to be(false)
    end
  end
end
