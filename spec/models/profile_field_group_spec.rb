require 'rails_helper'

RSpec.describe ProfileFieldGroup, type: :model do
  it { is_expected.to have_many(:profile_fields).dependent(:nullify) }
  it { is_expected.to validate_presence_of(:name) }
end
