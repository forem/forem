module DataUpdateScripts
  class FillBadgeCategoryForBadges
    def run
      category = BadgeCategory.find_by(name: BadgeCategory::DEFAULT_CATEGORY_NAME)
      category ||= BadgeCategory.create!(
        name: BadgeCategory::DEFAULT_CATEGORY_NAME,
        description: "Stay up-to-date with the latest achievements",
      )

      Badge.where.missing(:badge_category).each do |badge|
        badge.update!(badge_category_id: category.id)
      end
    end
  end
end
