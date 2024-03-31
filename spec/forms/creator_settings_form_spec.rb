require "rails_helper"

RSpec.describe CreatorSettingsForm, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:community_name) }
    it { is_expected.to validate_presence_of(:primary_brand_color_hex) }
  end

  describe "attributes" do
    it "has the correct attribute names" do
      expect(described_class.attribute_names).to eq(%w[checked_code_of_conduct checked_terms_and_conditions
                                                       community_name invite_only_mode logo
                                                       primary_brand_color_hex public])
    end

    it "sets default values", :aggregate_failures do
      attributes = described_class.new.attributes
      expect(attributes["checked_code_of_conduct"]).to be(false)
      expect(attributes["checked_terms_and_conditions"]).to be(false)
    end
  end

  describe "initializer" do
    it "updates the values when we pass an attribute as a param", :aggregate_failures do
      attributes = described_class.new(
        primary_brand_color_hex: "#0a0a0a",
        invite_only_mode: false,
      ).attributes
      expect(attributes["primary_brand_color_hex"]).to eq("#0a0a0a")
      expect(attributes["invite_only_mode"]).to be(false)
    end
  end

  describe "#save" do
    let(:current_user) { create(:user) }
    let(:form_data) do
      { checked_code_of_conduct: true,
        checked_terms_and_conditions: true,
        community_name: "Climbing Life",
        invite_only_mode: false,
        public: false,
        logo: "logo.png",
        primary_brand_color_hex: "#a81adb" }
    end

    after do
      Settings::Community.clear_cache
      Settings::UserExperience.clear_cache
      Settings::Authentication.clear_cache
    end

    it "saves the updated attributes to the correct Settings values" do
      # NOTE: override the profile migration hack from rails_helper.rb
      # TODO: remove this once we remove it in rails_helper.rb
      allow(Settings::UserExperience).to receive(:public).and_call_original

      creator_settings_form = described_class.new(form_data)
      expect(creator_settings_form.valid?).to be(true)

      creator_settings_form.save
      expect(creator_settings_form.success).to be(true)
      expect(Settings::Community.community_name).to eq("Climbing Life")
      expect(Settings::UserExperience.primary_brand_color_hex).to eq("#a81adb")
      expect(Settings::UserExperience.public).to be(false)
      expect(Settings::Authentication.invite_only_mode).to be(false)
      expect(current_user.checked_code_of_conduct).to be(true)
      expect(current_user.checked_terms_and_conditions).to be(true)
    end
  end
end
