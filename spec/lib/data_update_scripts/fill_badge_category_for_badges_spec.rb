require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20231123092607_fill_badge_category_for_badges.rb",
)

describe DataUpdateScripts::FillBadgeCategoryForBadges do
  let!(:uncoupled_badge) do
    create(:badge).tap do |created_badge|
      created_badge.update_column(:badge_category_id, nil)
    end
  end

  it "updates existing badges with the default badge category" do
    expect { described_class.new.run }
      .to change { uncoupled_badge.reload.badge_category_id }
      .from(nil)
      .to(an_instance_of(Integer))
  end

  it "updates badges counter of Badge Category" do
    expect { described_class.new.run }
      .to change { BadgeCategory.find_by(name: Constants::BadgeCategory::DEFAULT_CATEGORY_NAME)&.badges_count }
      .from(nil)
      .to(1)
  end

  it "works if the category with default name exist" do
    badge_category = create(:badge_category, name: Constants::BadgeCategory::DEFAULT_CATEGORY_NAME)

    expect { described_class.new.run }
      .to change { uncoupled_badge.reload.badge_category_id }
      .from(nil)
      .to(badge_category.id)
  end
end
