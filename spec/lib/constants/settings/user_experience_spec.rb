require "rails_helper"

RSpec.describe Constants::Settings::UserExperience do
  describe "SUPPORTED_LOCALES" do
    let(:translated_locales) do
      Dir[Rails.root.join("config/locales/*.yml")]
        .map { |path| File.basename(path, ".yml") }
        .reject { |name| name.include?(".") }
        .sort
    end

    it "offers every locale that ships a translation file" do
      expect(described_class::SUPPORTED_LOCALES.keys.sort).to eq(translated_locales)
    end

    it "includes Portuguese" do
      expect(described_class::SUPPORTED_LOCALES).to include("pt")
    end

    it "is frozen" do
      expect(described_class::SUPPORTED_LOCALES).to be_frozen
    end
  end

  describe ".locale_options" do
    it "returns label and code pairs usable by options_for_select" do
      expect(described_class.locale_options).to include(["Português", "pt"])
    end

    it "returns a pair for every supported locale" do
      expect(described_class.locale_options.size).to eq(described_class::SUPPORTED_LOCALES.size)
    end
  end
end
