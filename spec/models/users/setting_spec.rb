require "rails_helper"
# rubocop:disable Layout/LineLength
RSpec.describe Users::Setting, type: :model do
  describe "validations" do
    subject { setting }

    let(:setting) { create(:users_setting, user: user) }
    let(:user) { create(:user) }

    it { is_expected.to validate_length_of(:inbox_guidelines).is_at_most(250).allow_nil }
    it { is_expected.to define_enum_for(:inbox_type).with_values(private: 0, open: 1).with_suffix(:inbox) }
    it { is_expected.to define_enum_for(:config_font).with_values(default: 0, comic_sans: 1, monospace: 2, open_dyslexic: 3, sans_serif: 4, serif: 5) }
    it { is_expected.to define_enum_for(:config_navbar).with_values(default_navbar: 0, static_navbar: 1) }
    it { is_expected.to define_enum_for(:config_theme).with_values(default_theme: 0, minimal_light_theme: 1, night_theme: 2, pink_theme: 3, ten_x_hacker_theme: 4) }

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
        setting.config_theme = 2
        expect(setting).to be_valid
        expect(setting.night_theme?).to be true
      end

      it "does not accept invalid theme" do
        expect { setting.config_theme = 10 }.to raise_error(ArgumentError)
      end
    end

    describe "#config_font" do
      it "accepts valid font" do
        setting.config_font = 4
        expect(setting).to be_valid
        expect(setting.sans_serif?).to be true
      end

      it "does not accept invalid font" do
        expect { setting.config_font = 10 }.to raise_error(ArgumentError)
      end
    end

    describe "#config_navbar" do
      it "accepts valid navbar" do
        setting.config_navbar = 1
        expect(setting).to be_valid
        expect(setting.static_navbar?).to be true
      end

      it "does not accept invalid navbar" do
        expect { setting.config_navbar = 10 }.to raise_error(ArgumentError)
      end
    end
  end
end
# rubocop:enable Layout/LineLength
