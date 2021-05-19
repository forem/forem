require "rails_helper"

RSpec.describe SiteConfig, type: :model do
  describe "validations" do
    describe "validating URLs" do
      let(:url_fields) do
        %w[
          main_social_image logo_png mascot_image_url onboarding_background_image
        ]
      end

      it "accepts valid URLs" do
        url_fields.each do |attribute|
          expect do
            described_class.public_send("#{attribute}=", "https://example.com")
          end.not_to raise_error
        end
      end

      it "rejects invalid URLs and accepts valid ones", :aggregate_failures do
        url_fields.each do |attribute|
          expect do
            described_class.public_send("#{attribute}=", "example.com")
          end.to raise_error(/is not a valid URL/)
        end
      end
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
