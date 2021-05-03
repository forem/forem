require "rails_helper"

RSpec.describe SiteConfig, type: :model do
  describe "validations" do
    describe "validating URLs" do
      let(:url_fields) do
        %w[
          main_social_image logo_png mascot_image_url mascot_footer_image_url onboarding_background_image
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

    describe "validating hex string format" do
      it "allows 3 chacter hex strings" do
        expect do
          described_class.primary_brand_color_hex = "#000"
        end.not_to raise_error
      end

      it "allows 6 character hex strings" do
        expect do
          described_class.primary_brand_color_hex = "#000000"
        end.not_to raise_error
      end

      it "rejects strings without leading #" do
        expect do
          described_class.primary_brand_color_hex = "000000"
        end.to raise_error(/must be be a 3 or 6 character hex \(starting with #\)/)
      end

      it "rejects invalid character" do
        expect do
          described_class.primary_brand_color_hex = "#00000g"
        end.to raise_error(/must be be a 3 or 6 character hex \(starting with #\)/)
      end
    end

    describe "validating color contrast" do
      it "allows high enough color contrast" do
        expect do
          described_class.primary_brand_color_hex = "#000"
        end.not_to raise_error
      end

      it "rejects too low color contrast" do
        expect do
          described_class.primary_brand_color_hex = "#fff"
        end.to raise_error(/must be darker for accessibility/)
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
