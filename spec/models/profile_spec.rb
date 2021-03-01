require "rails_helper"

RSpec.describe Profile, type: :model do
  let(:user) { create(:user) }
  let(:profile) { user.profile }

  describe "validations" do
    subject { profile }

    it { is_expected.to validate_uniqueness_of(:user_id) }
    it { is_expected.to validate_presence_of(:data) }

    describe "conditionally validating summary" do
      let(:invalid_summary) { "x" * ProfileValidator::MAX_SUMMARY_LENGTH.next }

      it "doesn't validate if the profile field doesn't exist" do
        allow(ProfileField).to receive(:exists?).with(attribute_name: "summary").and_return(false)
        profile.summary = invalid_summary
        expect(profile).to be_valid
      end

      it "is valid if users previously had long summaries and are grandfathered" do
        profile.summary = invalid_summary
        profile.save(validate: false)
        profile.summary = "x" * 999
        expect(profile).to be_valid
      end

      it "is not valid if the summary is too long and the user is not grandfathered" do
        profile.summary = invalid_summary
        expect(profile).not_to be_valid
        expect(profile.errors_as_sentence).to eq "Summary is too long"
      end

      it "is valid if the summary is less than the limit" do
        profile.summary = "Hello 👋"
        expect(profile).to be_valid
      end
    end

    describe "validating color fields" do
      it "is valid if the field is a correct hex color with leading #" do
        profile.brand_color1 = "#abcdef"
        expect(profile).to be_valid
      end

      it "is valid if the field is a correct hex color without leading #" do
        profile.brand_color1 = "abcdef"
        expect(profile).to be_valid
      end

      it "is valid if the field is a 3-digit hex color" do
        profile.brand_color1 = "#ccc"
        expect(profile).to be_valid
      end

      it "is invalid if the field is too long" do
        profile.brand_color1 = "#deadbeef"
        expect(profile).not_to be_valid
        expect(profile.errors_as_sentence).to eq "Brand color1 is not a valid hex color"
      end

      it "is invalid if the field contains non hex characters" do
        profile.brand_color1 = "#abcdeg"
        expect(profile).not_to be_valid
        expect(profile.errors_as_sentence).to eq "Brand color1 is not a valid hex color"
      end
    end

    describe "validating text areas" do
      it "is valid if the text is short enough" do
        profile.skills_languages = "Ruby"
        expect(profile).to be_valid
      end

      it "is invalid if the text is too long" do
        profile.skills_languages = "x" * ProfileValidator::MAX_TEXT_AREA_LENGTH.next
        expect(profile).not_to be_valid
        expect(profile.errors_as_sentence).to eq "Skills languages is too long (maximum: 200)"
      end
    end

    describe "validating text fields" do
      it "is valid if the text is short enough" do
        profile.location = "Somewhere"
        expect(profile).to be_valid
      end

      it "is invalid if the text is too long" do
        profile.location = "x" * ProfileValidator::MAX_TEXT_FIELD_LENGTH.next
        expect(profile).not_to be_valid
        expect(profile.errors_as_sentence).to eq "Location is too long (maximum: 100)"
      end
    end
  end

  context "when accessing profile fields" do
    before do
      create(:profile_field, label: "Test 1")
      create(:profile_field, label: "Test 2", input_type: :check_box)
      described_class.refresh_attributes!
    end

    let(:profile) { described_class.new }

    it "defines accessors for active profile fields", :aggregate_failures do
      expect(profile).to respond_to(:test1)
      expect(profile).to respond_to(:test2)
    end

    it "performs ActiveRecord typecasting for profile fields", :aggregate_failures do
      expect do
        profile.test2 = "true"
      end.to change(profile, :test2).from(nil).to(true)

      expect do
        profile.test2 = "f"
      end.to change(profile, :test2).to(false)
    end
  end
end
