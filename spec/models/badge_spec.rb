require "rails_helper"

RSpec.describe Badge, type: :model do
  describe "validations" do
    subject { Badge.create(title: Faker::Overwatch.quote, description: Faker::Lorem.sentence) }

    it { is_expected.to have_many(:users).through(:badge_achievements) }
    it { is_expected.to have_many(:badge_achievements) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_uniqueness_of(:title) }
  end
end
