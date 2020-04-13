require "rails_helper"

RSpec.describe UserOptionalField, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:field) }
  it { is_expected.to validate_length_of(:field).is_at_most(30) }
  it { is_expected.to validate_presence_of(:value) }
  it { is_expected.to validate_length_of(:value).is_at_most(128) }
end
