require "rails_helper"

RSpec.describe AudienceSegment do
  subject(:audience_segment) { build(:audience_segment) }

  it { is_expected.to define_enum_for(:type_of) }
  it { is_expected.to be_valid }
end
