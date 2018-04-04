require "rails_helper"

RSpec.describe ChatChannel, type: :model do
  it { is_expected.to have_many(:messages) }
  it { is_expected.to validate_presence_of(:channel_type) }
end
