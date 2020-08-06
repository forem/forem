require "rails_helper"

RSpec.describe ProfileField, type: :model do
  let(:profile_field) { create(:profile_field) }

  describe "validations" do
    describe "builtin validations" do
      subject { profile_field }

      it { is_expected.to validate_presence_of(:label) }
      it { is_expected.to validate_uniqueness_of(:label).case_insensitive }
      it { is_expected.to validate_inclusion_of(:active).in_array([true, false]) }
    end
  end
end
