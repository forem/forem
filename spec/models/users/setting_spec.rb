require "rails_helper"
# rubocop:disable Layout/LineLength
RSpec.describe Users::Setting, type: :model do
  describe "validations" do
    subject { setting }

    let(:user) { create(:user) }
    let(:setting) { user.setting }

    it { is_expected.to validate_length_of(:inbox_guidelines).is_at_most(250).allow_nil }
    it { is_expected.to define_enum_for(:inbox_type).with_values(private: 0, open: 1).with_suffix(:inbox) }
    it { is_expected.to define_enum_for(:config_font).with_values(default: 0, comic_sans: 1, monospace: 2, open_dyslexic: 3, sans_serif: 4, serif: 5).with_suffix(:font) }
    it { is_expected.to define_enum_for(:config_navbar).with_values(default: 0, static: 1).with_suffix(:navbar) }
    it { is_expected.to define_enum_for(:config_theme).with_values(default: 0, minimal_light_theme: 1, night_theme: 2, pink_theme: 3, ten_x_hacker_theme: 4) }

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
        expect(setting.sans_serif_font?).to be true
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
