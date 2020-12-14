require "rails_helper"

RSpec.describe SiteConfig, type: :model do
  describe "validations" do
    describe "builtin validations" do
      it { is_expected.to validate_presence_of(:var) }
    end
  end

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

  describe ".dev_to?" do
    it "returns true if the .app_domain is dev.to" do
      allow(described_class).to receive(:app_domain).and_return("dev.to")

      expect(described_class.dev_to?).to be(true)
    end

    it "returns false if the .app_domain is not dev.to" do
      allow(described_class).to receive(:app_domain).and_return("forem.dev")

      expect(described_class.dev_to?).to be(false)
    end
  end
end
