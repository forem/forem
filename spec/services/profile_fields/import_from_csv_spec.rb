require "rails_helper"

RSpec.describe ProfileFields::ImportFromCsv do
  it "ignores empty lines" do
    expect do
      described_class.call(file_fixture("profile_fields.csv"))
    end.to change(ProfileField, :count).by(3)
  end

  context "when missing attributes" do
    before { described_class.call(file_fixture("profile_fields.csv")) }

    it "handles missing descriptions", :aggregate_failures do
      field = ProfileField.find_by!(label: "Test name")
      expect(field.input_type).to eq "text_field"
      expect(field.placeholder_text).to eq "John Doe"
      expect(field.description).to be_nil
      expect(field.profile_field_group.name).to eq "Basic"
    end

    it "handles missing placeholder_texts", :aggregate_failures do
      field = ProfileField.find_by!(label: "Test languages")
      expect(field.input_type).to eq "text_area"
      expect(field.placeholder_text).to be_nil
      expect(field.description).to eq "Programming languages"
      expect(field.profile_field_group.name).to eq "Coding"
    end

    it "handles commas in correctly quoted fields", :aggregate_failures do
      field = ProfileField.find_by!(label: "Test color")
      expect(field.input_type).to eq "color_field"
      expect(field.placeholder_text).to eq "#000000"
      expect(field.description).to eq "Used for backgrounds, borders etc."
      expect(field.profile_field_group.name).to eq "Branding"
    end
  end
end
