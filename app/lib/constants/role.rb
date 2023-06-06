module Constants
  module Role
    BASE_ROLES_LABELS_TO_WHERE_CLAUSE = {
      "Warned" => { name: ::Role::ROLES[:warned], resource_type: nil },
      "Comment Suspended" => { name: ::Role::ROLES[:comment_suspended], resource_type: nil },
      "Suspended" => { name: ::Role::ROLES[:suspended], resource_type: nil },
      # This "role" is a weird amalgamation of multiple roles.
      "Good standing" => :good_standing,
      "Trusted" => { name: ::Role::ROLES[:trusted], resource_type: nil }
    }.freeze

    BASE_ROLES = BASE_ROLES_LABELS_TO_WHERE_CLAUSE.keys.freeze

    SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE = {
      "Admin" => { name: ::Role::ROLES[:admin], resource_type: nil },
      "Tech Admin" => { name: ::Role::ROLES[:tech_admin], resource_type: nil },
      "Super Admin" => { name: ::Role::ROLES[:super_admin], resource_type: nil },
      "Resource Admin: Article" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "Article" },
      "Resource Admin: Badge" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "Badge" },
      "Resource Admin: BadgeAchievement" => { name: ::Role::ROLES[:single_resource_admin],
                                              resource_type: "BadgeAchievement" },
      "Resource Admin: Broadcast" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "Broadcast" },
      "Resource Admin: Comment" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "Comment" },
      "Resource Admin: Config" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "Config" },
      "Resource Admin: DisplayAd" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "DisplayAd" },
      "Resource Admin: DataUpdateScript" => { name: ::Role::ROLES[:single_resource_admin],
                                              resource_type: "DataUpdateScript" },
      "Resource Admin: FeedbackMessage" => { name: ::Role::ROLES[:single_resource_admin],
                                             resource_type: "FeedbackMessage" },
      "Resource Admin: HtmlVariant" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "HtmlVariant" },
      "Resource Admin: ListingCategory" => { name: ::Role::ROLES[:single_resource_admin],
                                             resource_type: "ListingCategory" },
      "Resource Admin: Page" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "Page" },
      "Resource Admin: Tag" => { name: ::Role::ROLES[:single_resource_admin], resource_type: "Tag" }
    }.freeze

    SPECIAL_ROLES = SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE.keys.freeze

    ALL_ROLES_LABELS_TO_WHERE_CLAUSE =
      SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE.merge(BASE_ROLES_LABELS_TO_WHERE_CLAUSE).freeze
  end
end
