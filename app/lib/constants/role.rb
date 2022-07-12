module Constants
  module Role
    BASE_ROLES_LABELS_TO_WHERE_CLAUSE = {
      "Warned" => { name: "warned", resource_type: nil },
      "Comment Suspended" => { name: "comment_suspended", resource_type: nil },
      "Suspended" => { name: "suspended", resource_type: nil },
      # This "role" is a weird amalgamation of multiple roles.
      "Good standing" => :good_standing,
      "Trusted" => { name: "trusted", resource_type: nil }
    }.freeze

    BASE_ROLES = BASE_ROLES_LABELS_TO_WHERE_CLAUSE.keys.freeze

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

    ALL_ROLES_LABELS_TO_WHERE_CLAUSE =
      SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE.merge(BASE_ROLES_LABELS_TO_WHERE_CLAUSE).freeze
  end
end
