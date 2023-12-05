module DataUpdateScripts
  class FillBadgeCategoryForBadges
    def run
      category = BadgeCategory.find_by(name: Constants::BadgeCategory::DEFAULT_CATEGORY_NAME)
      category ||= BadgeCategory.create!(
        name: Constants::BadgeCategory::DEFAULT_CATEGORY_NAME,
        description: "Stay up-to-date with the latest achievements",
      )

      Badge.where(badge_category: nil).find_each do |badge|
        badge.update!(badge_category_id: category.id)
      end
    end
  end
end
