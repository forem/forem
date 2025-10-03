require "rails_helper"
# rubocop:disable Layout/LineLength
RSpec.describe Users::Setting do
  let(:user) { create(:user) }
  let(:setting) { described_class.find_by(user_id: user.id) }

  before do
    allow(SegmentedUserRefreshWorker).to receive(:perform_async)
  end

  describe "validations" do
    subject { setting }

    it { is_expected.to validate_length_of(:inbox_guidelines).is_at_most(250).allow_nil }
    it { is_expected.to validate_numericality_of(:experience_level).is_in(1..10) }
    it { is_expected.to validate_inclusion_of(:disallow_subforem_reassignment).in_array([true, false]) }
    it { is_expected.to define_enum_for(:inbox_type).with_values(private: 0, open: 1).with_suffix(:inbox) }
    it { is_expected.to define_enum_for(:config_font).with_values(default: 0, comic_sans: 1, monospace: 2, open_dyslexic: 3, sans_serif: 4, serif: 5).with_suffix(:font) }
    it { is_expected.to define_enum_for(:config_navbar).with_values(default: 0, static: 1).with_suffix(:navbar) }
    it { is_expected.to define_enum_for(:config_theme).with_values(light_theme: 0, dark_theme: 2) }
    it { is_expected.to define_enum_for(:config_homepage_feed).with_values(default: 0, latest: 1, top_week: 2, top_month: 3, top_year: 4, top_infinity: 5).with_suffix(:feed) }

    describe "validating color fields" do
      it "is valid if the field is a correct hex color with leading #" do
        setting.brand_color1 = "#abcdef"
        expect(setting).to be_valid
      end

      it "is valid if the field is a correct hex color without leading #" do
        setting.brand_color1 = "abcdef"
        expect(setting).to be_valid
      end

      it "is valid if the field is a 3-digit hex color" do
        setting.brand_color1 = "#ccc"
        expect(setting).to be_valid
      end

      it "is valid if the brand color is nil" do
        setting.brand_color1 = nil
        expect(setting).to be_valid
      end

      it "is invalid if the field is too long" do
        setting.brand_color1 = "#deadbeef"
        expect(setting).not_to be_valid
        expect(setting.errors_as_sentence).to eq "Brand color1 is not a valid hex color"
      end

      it "is invalid if the field contains non hex characters" do
        setting.brand_color1 = "#abcdeg"
        expect(setting).not_to be_valid
        expect(setting.errors_as_sentence).to eq "Brand color1 is not a valid hex color"
      end
    end

    describe "#config_theme" do
      it "accepts valid theme" do
        setting.config_theme = 2
        expect(setting).to be_valid
        expect(setting.dark_theme?).to be true
      end

      it "does not accept invalid theme" do
        expect { setting.config_theme = 10 }.to raise_error(ArgumentError)
      end
    end

    describe "#content_preferences_input" do
      it "updates content_preferences_updated_at if changed" do
        setting.content_preferences_input = "New content preferences"
        setting.save
        expect(setting.content_preferences_updated_at).to be_within(1.second).of(Time.current)
      end

      it "does not update content_preferences_updated_at if empty" do
        setting.content_preferences_input = ""
        setting.save
        expect(setting.content_preferences_updated_at).to eq setting.content_preferences_updated_at_before_last_save
      end

      it "does not update if not changed" do
        setting.content_preferences_input = "New content preferences"
        setting.save
        setting.content_preferences_input = "New content preferences"
        setting.save
        expect(setting.content_preferences_updated_at).to eq setting.content_preferences_updated_at_before_last_save
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

    describe "#config_homepage_feed" do
      it "accepts valid feed type" do
        setting.config_homepage_feed = 1
        expect(setting).to be_valid
        expect(setting.latest_feed?).to be true
      end

      it "does not accept invalid feed type" do
        expect { setting.config_homepage_feed = 10 }.to raise_error(ArgumentError)
      end
    end

    context "when validating feed_url", :vcr do
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
  end

  describe "#resolved_font_name" do
    it "replaces 'default' with font configured for the site in Settings::General" do
      expect(setting.config_font).to eq("default")
      %w[sans_serif serif open_dyslexic].each do |font|
        allow(Settings::UserExperience).to receive(:default_font).and_return(font)
        expect(setting.resolved_font_name).to eq(font)
      end
    end

    it "doesn't replace the user's custom selected font" do
      user_comic_sans = create(:user)
      user_comic_sans.setting.update(config_font: "comic_sans")
      allow(Settings::UserExperience).to receive(:default_font).and_return("open_dyslexic")
      expect(user_comic_sans.setting.resolved_font_name).to eq("comic_sans")
    end
  end

  context "when updating a setting" do
    it "refreshes user segment" do
      setting.experience_level = setting.experience_level.to_i + 1
      setting.save!
      expect(SegmentedUserRefreshWorker).to have_received(:perform_async).with(user.id)
    end
  end

  context "when creating from scratch" do
    it "does not refresh user segment" do
      create(:user).setting
      expect(SegmentedUserRefreshWorker).not_to have_received(:perform_async)
    end
  end
end
# rubocop:enable Layout/LineLength
