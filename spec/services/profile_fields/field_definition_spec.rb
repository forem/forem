require "rails_helper"

RSpec.describe ProfileFields::FieldDefinition, type: :service do
  let(:test_class) do
    Class.new do
      include ProfileFields::FieldDefinition
      group "DSL Test" do
        field "Test 1", :text_area, placeholder: "Test", description: "For testing"
        field "Test 2", :check_box
      end
    end
  end

  context "when adding fields" do
    it "creates all the profile fields in the DB", :aggregate_failures do
      expect do
        test_class.call
      end.to change(ProfileField, :count).by(2)

      labels = ProfileField.pluck(:label)
      expect(labels).to include("Test 1")
      expect(labels).to include("Test 2")
      group = ProfileFieldGroup.find_by(name: "DSL Test")
      expect(ProfileField.pluck(:profile_field_group_id).count(group.id)).to eq(2)
    end
  end
end
