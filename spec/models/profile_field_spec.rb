require "rails_helper"

RSpec.describe ProfileField, type: :model do
  let(:profile_field) { create(:profile_field) }

  describe "validations" do
    describe "builtin validations" do
      subject { profile_field }

      it { is_expected.to validate_presence_of(:label) }
      it { is_expected.to validate_uniqueness_of(:label).case_insensitive }
      it { is_expected.to validate_presence_of(:attribute_name).on(:update) }
      it { is_expected.to validate_inclusion_of(:show_in_onboarding).in_array([true, false]) }
    end
  end

  describe "callbacks" do
    it "automatically generates an attribute name" do
      pf = create(:profile_field, label: "Is this a test? This is a test! 1")
      expect(pf.attribute_name).to eq "is_this_a_test_this_is_a_test1"
    end
  end
end
