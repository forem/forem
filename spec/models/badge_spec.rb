require "rails_helper"

RSpec.describe Badge, type: :model do
  let_it_be(:badge) { create(:badge) }

  describe "validations" do
    it { is_expected.to have_many(:users).through(:badge_achievements) }
    it { is_expected.to have_many(:badge_achievements) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:badge_image) }
    it { is_expected.to validate_uniqueness_of(:title) }
  end
end
