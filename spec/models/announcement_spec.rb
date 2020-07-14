require "rails_helper"

RSpec.describe Announcement, type: :model do
  it { is_expected.to validate_inclusion_of(:banner_style).in_array(%w[default brand success warning error]) }
  it { is_expected.to have_one(:broadcast) }
end
