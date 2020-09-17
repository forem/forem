RSpec.shared_examples "a profile field" do
  let(:profile_field_class) { described_class.name.underscore }

  describe "validations" do
    describe "builtin validations" do
      subject { create(profile_field_class) }

      it { is_expected.to validate_presence_of(:label) }
      it { is_expected.to validate_uniqueness_of(:label).case_insensitive }
      it { is_expected.to validate_presence_of(:attribute_name).on(:update) }
    end
  end

  describe "callbacks" do
    it "automatically generates an attribute name" do
      field = create(profile_field_class, label: "Test? Test! 1")
      expect(field.attribute_name).to eq "test_test1"
    end
  end
end
