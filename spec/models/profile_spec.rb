require "rails_helper"

RSpec.describe Profile, type: :model do
  let(:user) { create(:user) }
  let(:profile) { user.profile }

  describe "validations" do
    subject { profile }

    it { is_expected.to validate_uniqueness_of(:user_id) }

    describe "conditionally validating summary" do
      let(:invalid_summary) { "x" * ProfileValidator::MAX_SUMMARY_LENGTH.next }

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

      it "counts line ending as a single character when summary is multi line" do
        profile.summary = "#{'x' * ProfileValidator::MAX_SUMMARY_LENGTH.pred}\r\n"
        expect(profile).to be_valid
      end
    end

    describe "validating text areas" do
      let(:text_area_get) { ProfileField.find_by(label: "Test Text Area")&.attribute_name }
      let(:text_area_set) { "#{text_area_get}=" }

      before do
        create(:profile_field, label: "Test Text Area", input_type: :text_area)
      end

      it "is valid if the text is short enough" do
        profile.public_send(text_area_set, "Ruby")
        expect(profile).to be_valid
      end

      it "is invalid if the text is too long" do
        profile.public_send(text_area_set, "x" * ProfileValidator::MAX_TEXT_AREA_LENGTH.next)
        expect(profile).not_to be_valid
        expect(profile.errors_as_sentence)
          .to include("is too long (maximum is 200 characters)")
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
        expect(profile.errors_as_sentence).to eq "Location is too long (maximum is 100 characters)"
      end
    end

    describe "validating website_url" do
      it "is valid if blank" do
        profile.website_url = nil
        expect(profile).to be_valid
      end

      it "is valid with a complete url" do
        profile.website_url = "https://dev.to"
        expect(profile).to be_valid
      end

      it "is invalid with an incomplete url" do
        profile.website_url = "dev.to"
        expect(profile).not_to be_valid
        expect(profile.errors_as_sentence).to eq "Website url is not a valid URL"
      end
    end
  end

  context "when accessing profile fields" do
    before do
      create(:profile_field, label: "Test 1")
      create(:profile_field, label: "Test 2", input_type: :text_area)
    end

    let(:profile) { described_class.new }

    let(:test1) { ProfileField.find_by(label: "Test 1").attribute_name }
    let(:test2) { ProfileField.find_by(label: "Test 2").attribute_name }

    it "defines accessors for active profile fields", :aggregate_failures do
      expect(profile).to respond_to(test1)
      expect(profile).to respond_to(test2)
    end
  end
end
