require "rails_helper"

RSpec.describe BadgeCategory do
  let(:badge_category) { create(:badge_category) }

  describe "validations" do
    subject { badge_category }

    it { is_expected.to have_many(:badges).dependent(:restrict_with_error) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
  end

  it "increments `badges_count` by 1 when a new badge is created" do
    expect { create(:badge, badge_category: badge_category) }
      .to change(badge_category, :badges_count)
      .by(1)
  end

  it "decrements `badges_count` by 1 when a badge is destroyed" do
    badge = create(:badge, badge_category: badge_category)
    expect { badge.destroy! }
      .to change(badge_category, :badges_count)
      .by(-1)
  end
end
