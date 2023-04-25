require "rails_helper"

RSpec.describe SegmentedUser do
  it { is_expected.to belong_to(:audience_segment) }
  it { is_expected.to belong_to(:user) }
end
