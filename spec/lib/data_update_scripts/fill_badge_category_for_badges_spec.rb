require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20231123092607_fill_badge_category_for_badges.rb",
)

describe DataUpdateScripts::FillBadgeCategoryForBadges do
  let(:badge_category_with_default_category_name) do
    create(:badge_category, name: Constants::BadgeCategory::DEFAULT_CATEGORY_NAME)
  end
  let(:uncoupled_badge) { make_uncoupled_badge }

  def make_uncoupled_badge
    create(:badge).tap do |created_badge|
      created_badge.update_column(:badge_category_id, nil)
    end
  end

  before do
    make_uncoupled_badge
  end

  it "updates existing badges with the default badge category" do
    expect { described_class.new.run }
      .to change { uncoupled_badge&.reload&.badge_category&.name }
      .from(nil)
      .to(Constants::BadgeCategory::DEFAULT_CATEGORY_NAME)
  end

  it "updates badges counter of Badge Category'" do
    expect { described_class.new.run }
      .to change { badge_category_with_default_category_name.reload.badges_count }
      .by(1)
  end
end
