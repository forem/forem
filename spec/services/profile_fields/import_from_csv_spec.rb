require "rails_helper"

RSpec.describe ProfileFields::ImportFromCsv do
  # Importing is slow, so we only do it once and then clean up after outselves.
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) { described_class.call(file_fixture("profile_fields.csv")) }

  after(:all) { ProfileField.destroy_all }
  # rubocop:enable RSpec/BeforeAfterAll

  it "ignores empty lines" do
    expect(ProfileField.count).to eq 3
  end

  it "handles missing descriptions", :aggregate_failures do
    field = ProfileField.find_by!(label: "Name")
    expect(field.input_type).to eq "text_field"
    expect(field.placeholder_text).to eq "John Doe"
    expect(field.description).to be_nil
    expect(field.group).to eq "Basic"
  end

  it "handles missing placeholder_texts", :aggregate_failures do
    field = ProfileField.find_by!(label: "Skills/Languages")
    expect(field.input_type).to eq "text_area"
    expect(field.placeholder_text).to be_nil
    expect(field.description).to eq "Programming languages"
    expect(field.group).to eq "Coding"
  end

  it "handles commas in correctly quoted fields", :aggregate_failures do
    field = ProfileField.find_by!(label: "Color")
    expect(field.input_type).to eq "color_field"
    expect(field.placeholder_text).to eq "#000000"
    expect(field.description).to eq "Used for backgrounds, borders etc."
    expect(field.group).to eq "Branding"
  end
end
