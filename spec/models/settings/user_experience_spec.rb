require "rails_helper"

RSpec.describe Settings::UserExperience do
  before { described_class.clear_cache }
  after { described_class.clear_cache }

  describe "sticky feed settings" do
    it "defaults to 60 hours, 50 percent, and a 30-minute reward interval" do
      expect(described_class.feed_config_sticky_hours).to eq(60)
      expect(described_class.feed_config_sticky_percentage).to eq(50)
      expect(described_class.feed_config_repeat_visit_minutes).to eq(30)
    end

    it "allows disabling sticky selection and configuring the interval" do
      described_class.feed_config_sticky_hours = 0
      described_class.feed_config_sticky_percentage = 0
      described_class.feed_config_repeat_visit_minutes = 45
      expect(described_class.feed_config_sticky_hours).to eq(0)
      expect(described_class.feed_config_sticky_percentage).to eq(0)
      expect(described_class.feed_config_repeat_visit_minutes).to eq(45)
    end

    it "accepts a fully sticky feed" do
      expect { described_class.feed_config_sticky_percentage = 100 }.not_to raise_error
    end

    {
      feed_config_sticky_hours: [-1],
      feed_config_sticky_percentage: [-1, 101],
      feed_config_repeat_visit_minutes: [0, -1]
    }.each do |setting, invalid_values|
      invalid_values.each do |value|
        it "rejects #{setting} of #{value}" do
          expect { described_class.public_send(:"#{setting}=", value) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  describe "validating hex string format" do
    it "allows 3 character hex strings" do
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

  describe "cover image settings" do
    it "has a default cover_image_height of 420" do
      expect(described_class.cover_image_height).to eq(420)
    end

    it "has a default cover_image_fit of 'crop'" do
      expect(described_class.cover_image_fit).to eq("crop")
    end

    it "allows setting cover_image_height" do
      described_class.cover_image_height = 500
      expect(described_class.cover_image_height).to eq(500)
    end

    it "allows setting cover_image_fit to 'limit'" do
      described_class.cover_image_fit = "limit"
      expect(described_class.cover_image_fit).to eq("limit")
    end

    it "rejects invalid cover_image_fit values" do
      expect do
        described_class.cover_image_fit = "invalid"
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "cover_image_aesthetic_instructions" do
    it "has an empty default value" do
      expect(described_class.cover_image_aesthetic_instructions).to eq("")
    end

    it "allows setting aesthetic instructions" do
      aesthetic = "vibrant and modern with bold colors"
      described_class.cover_image_aesthetic_instructions = aesthetic
      expect(described_class.cover_image_aesthetic_instructions).to eq(aesthetic)
    end

    it "allows clearing aesthetic instructions" do
      described_class.cover_image_aesthetic_instructions = "some instructions"
      described_class.cover_image_aesthetic_instructions = ""
      expect(described_class.cover_image_aesthetic_instructions).to eq("")
    end

    it "allows setting aesthetic instructions for specific subforem" do
      subforem = create(:subforem)
      aesthetic = "minimalist and clean"
      
      described_class.set_cover_image_aesthetic_instructions(aesthetic, subforem_id: subforem.id)
      expect(described_class.cover_image_aesthetic_instructions(subforem_id: subforem.id)).to eq(aesthetic)
    end
  end
end
