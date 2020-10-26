require "rails_helper"

RSpec.describe ProfileField, type: :model do
  it_behaves_like "a profile field"

  describe "validations" do
    describe "builtin validations" do
      it { is_expected.to belong_to(:profile_field_group).optional(true) }

      it { is_expected.to validate_presence_of(:display_area) }
      it { is_expected.to validate_presence_of(:input_type) }
      it { is_expected.to validate_inclusion_of(:show_in_onboarding).in_array([true, false]) }
    end
  end
end
