require "rails_helper"

RSpec.describe ProfileField, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:profile_field_group).optional(true) }
  end

  describe "validations" do
    describe "builtin validations" do
      it { is_expected.to validate_presence_of(:attribute_name).on(:update) }
      it { is_expected.to validate_presence_of(:display_area) }
      it { is_expected.to validate_presence_of(:input_type) }
      it { is_expected.to validate_presence_of(:label) }
      it { is_expected.to validate_uniqueness_of(:label).case_insensitive }
    end
  end

  describe "callbacks" do
    it "automatically generates an attribute name" do
      field = create(:profile_field, label: "Test? Test! 1")
      expect(field.attribute_name).to eq "test_test1"
    end
  end
end
