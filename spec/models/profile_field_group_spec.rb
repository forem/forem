require "rails_helper"

RSpec.describe ProfileFieldGroup, type: :model do
  subject { create(:profile_field_group) }

  it { is_expected.to have_many(:profile_fields).dependent(:nullify) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
end
