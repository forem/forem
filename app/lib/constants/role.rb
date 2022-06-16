module Constants
  module Role
    BASE_ROLES = [
      "Warned",
      "Comment Suspended",
      "Suspended",
      "Good standing",
      "Trusted",
    ].freeze

    SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE = {
      "Admin" => { name: "admin", resource_type: nil },
      "Tech Admin" => { name: "tech_admin", resource_type: nil },
      "Super Admin" => { name: "super_admin", resource_type: nil },
      "Resource Admin: Article" => { name: "single_resource_admin", resource_type: "Article" },
      "Resource Admin: Badge" => { name: "single_resource_admin", resource_type: "Badge" },
      "Resource Admin: BadgeAchievement" => { name: "single_resource_admin", resource_type: "BadgeAchievement" },
      "Resource Admin: Broadcast" => { name: "single_resource_admin", resource_type: "Broadcast" },
      "Resource Admin: Comment" => { name: "single_resource_admin", resource_type: "Comment" },
      "Resource Admin: Config" => { name: "single_resource_admin", resource_type: "Config" },
      "Resource Admin: DisplayAd" => { name: "single_resource_admin", resource_type: "DisplayAd" },
      "Resource Admin: DataUpdateScript" => { name: "single_resource_admin", resource_type: "DataUpdateScript" },
      "Resource Admin: FeedbackMessage" => { name: "single_resource_admin", resource_type: "FeedbackMessage" },
      "Resource Admin: HtmlVariant" => { name: "single_resource_admin", resource_type: "HtmlVariant" },
      "Resource Admin: ListingCategory" => { name: "single_resource_admin", resource_type: "ListingCategory" },
      "Resource Admin: Page" => { name: "single_resource_admin", resource_type: "Page" },
      "Resource Admin: Tag" => { name: "single_resource_admin", resource_type: "Tag" }
    }.freeze

    SPECIAL_ROLES = SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE.keys.freeze
  end
end
