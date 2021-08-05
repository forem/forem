require "rails_helper"

RSpec.describe ProfileFields::ImportFromCsv do
  it "ignores empty lines" do
    expect do
      described_class.call(file_fixture("profile_fields.csv"))
    end.to change(ProfileField, :count).by(3)
  end

  context "when missing attributes" do
    before { described_class.call(file_fixture("profile_fields.csv")) }

    it "imports fields" do
      field = ProfileField.find_by!(label: "Full test")
      expect(field.input_type).to eq "text_field"
      expect(field.placeholder_text).to eq "Test"
      expect(field.description).to eq "Test field"
      expect(field.profile_field_group.name).to eq "Basic"
      expect(field.display_area).to eq "left_sidebar"
      expect(field.show_in_onboarding).to be true
    end

    it "handles missing descriptions" do
      field = ProfileField.find_by!(label: "Test name")
      expect(field.description).to be_nil
    end

    it "handles missing placeholder_texts" do
      field = ProfileField.find_by!(label: "Test languages")
      expect(field.placeholder_text).to be_nil
    end

    it "handles commas in correctly quoted fields" do
      field = ProfileField.find_by!(label: "Test languages")
      expect(field.description).to eq "Programming languages, frameworks, etc."
    end
  end
end
