module Admin
  module BadgesHelper
    def badge_categories_for_options
      BadgeCategory.pluck(:name, :id)
    end
  end
end
