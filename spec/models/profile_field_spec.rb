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

    describe "#maximum_header_field_count" do
      it "limits the number of header fields" do
        count = [0, described_class::HEADER_FIELD_LIMIT - described_class.header.count].max
        create_list(:profile_field, count, :header)

        expected_message = /#{Regexp.quote(ProfileField::HEADER_LIMIT_MESSAGE)}/

        expect { create(:profile_field, :header) }
          .to raise_error(ActiveRecord::RecordInvalid, expected_message)
      end
    end
  end
end
