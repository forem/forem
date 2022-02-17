# This "model" is not backed by the database. Its main purpose is to
# setup and provide methods to interact with the admin sidebar and tabbed menu
class AdminMenu
  # On second level navigation with more children, we reference the default tabs controller. i.e look at developer_tools
  # rubocop:disable Metrics/BlockLength
  FEATURE_FLAGS = %i[profile_admin data_update_scripts].freeze

  ITEMS = Menu.define do
    scope :people, "group-2-line", [
      item(name: "people", controller: "users", parent: "users"),
    ]

    scope :content_manager, "dashboard-line", [
      item(name: "posts", controller: "articles", parent: "content_manager"),
      item(name: "comments", controller: "comments", parent: "content_manager"),
      item(name: "badges", children: [
             item(name: "library", controller: "badges", parent: "content_manager"),
             item(name: "achievements", controller: "badge_achievements", parent: "content_manager"),
           ], parent: "content_manager"),
      item(name: "organizations", parent: "content_manager"),
      item(name: "podcasts", parent: "content_manager"),
      item(name: "tags", parent: "content_manager"),
    ]

    scope :customization, "tools-line", [
      item(name: "config", parent: "customization"),
      item(name: "html variants", controller: "html_variants", parent: "customization"),
      item(name: "display ads", parent: "customization"),
      item(name: "navigation links", parent: "customization"),
      item(name: "pages", parent: "customization"),
      item(name: "profile fields", visible: false, parent: "customization"),
    ]

    scope :admin_team, "user-line", [
      item(name: "admin team", controller: "permissions", parent: "permissions"),
    ]

    scope :moderation, "mod", [
      item(name: "reports", parent: "moderation"),
      item(name: "mods", parent: "moderation"),
      item(name: "moderator actions ads", controller: "moderator_actions", parent: "moderation"),
      item(name: "privileged reactions", parent: "moderation"),
      # item(name: "interaction limits")
    ]

    scope :advanced, "flashlight-line", [
      item(name: "broadcasts", parent: "advanced"),
      item(name: "response templates", parent: "advanced"),
      item(name: "sponsorships", parent: "advanced"),
      item(name: "developer tools", controller: "tools", children: [
             item(name: "tools", parent: "advanced"),
             item(name: "vault secrets", controller: "secrets", parent: "advanced"),
             item(name: "data update scripts", visible: false, parent: "advanced"),
           ]),
    ]

    scope :apps, "palette-line", [
      item(name: "consumer apps", controller: "consumer_apps", parent: "apps"),
      item(name: "listings", parent: "apps"),
      item(name: "welcome", parent: "apps"),
    ]
  end.freeze
  # rubocop:enable Metrics/BlockLength

  def self.navigation_items
    return ITEMS unless FEATURE_FLAGS.any? { |flag| FeatureFlag.enabled?(flag) }

    feature_flagged_menu_items
  end

  def self.nested_menu_items(scope_name, nav_item)
    return unless navigation_items.dig(scope_name.to_sym, :children)

    navigation_items.dig(scope_name.to_sym, :children).each do |items|
      return items if items[:controller] == nav_item

      next unless items[:children]&.any?

      items[:children].each do |child|
        return items if child[:controller] == nav_item
      end
    end
  end

  def self.nested_menu_items_from_request(request)
    scope, nav_item = request.path.split("/").last(2)
    nested_menu_items(scope, nav_item)
  end

  def self.feature_flagged_menu_items
    # We default to creating a ITEMS constant with visibility set to false
    # and then simply amend the visibility of the feature flag when it's
    # turned on, instead of creating the payload dynamically each time.
    menu_items = ITEMS.deep_dup

    if FeatureFlag.enabled?(:profile_admin)
      profile_hash = menu_items.dig(:customization, :children).detect { |item| item[:controller] == "profile_fields" }
      profile_hash[:visible] = true
    end

    if FeatureFlag.enabled?(:data_update_scripts)
      data_update_script_hash = menu_items.dig(:advanced, :children)
        .detect { |item| item[:controller] ==  "tools" }[:children]
        .detect { |item| item[:controller] ==  "data_update_scripts" }
      data_update_script_hash[:visible] = true
    end

    menu_items
  end
end
