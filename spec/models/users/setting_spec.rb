require "rails_helper"

RSpec.describe Users::Setting, type: :model do
  describe "validations" do
    let(:user) { create(:user) }
    let(:setting) { create(:setting, user: user) }
    subject { create(:setting, user: user) }

    it { is_expected.to validate_inclusion_of(:inbox_type).in_array(%w[open private]) }
    it { is_expected.to validate_length_of(:inbox_guidelines).is_at_most(250).allow_nil }
    it { is_expected.to validate_presence_of(:config_font) }
    it { is_expected.to validate_presence_of(:config_navbar) }
    it { is_expected.to validate_presence_of(:config_theme) }

    describe "when validating feed_url", vcr: true do
      it "is valid with no feed_url" do
        setting.feed_url = nil

        expect(setting).to be_valid
      end

      it "is not valid with an invalid feed_url", vcr: { cassette_name: "feeds_validate_url_invalid" } do
        setting.feed_url = "http://example.com"

        expect(setting).not_to be_valid
      end

      it "is valid with a valid feed_url", vcr: { cassette_name: "feeds_import_medium_vaidehi" } do
        setting.feed_url = "https://medium.com/feed/@vaidehijoshi"

        expect(setting).to be_valid
      end
    end

    describe "#config_theme" do
      it "accepts valid theme" do
        setting.config_theme = "night theme"
        expect(setting).to be_valid
      end

      it "does not accept invalid theme" do
        setting.config_theme = "no night mode"
        expect(setting).not_to be_valid
      end
    end

    describe "#config_font" do
      it "accepts valid font" do
        setting.config_font = "sans serif"
        expect(setting).to be_valid
      end

      it "does not accept invalid font" do
        setting.config_font = "goobledigook"
        expect(setting).not_to be_valid
      end
    end

    describe "#config_navbar" do
      it "accepts valid navbar" do
        setting.config_navbar = "static"
        expect(setting).to be_valid
      end

      it "does not accept invalid navbar" do
        setting.config_navbar = "not valid navbar input"
        expect(setting).not_to be_valid
      end
    end
  end
end
