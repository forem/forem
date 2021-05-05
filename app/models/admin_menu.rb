# This "model" is not backed by the database. Its main purpose is to
# setup and provide methods to interact with the admin sidebar and tabbed menu
class AdminMenu
  # On second level navigation with more children, we reference the default tabs controller. i.e look at developer_tools
  # rubocop:disable Metrics/BlockLength
  ITEMS = Menu.define do
    scope :people, "group-2-line", [
      item(name: "people", controller: "users"),
    ]

    scope :content_manager, "dashboard-line", [
      item(name: "posts", controller: "articles"),
      item(name: "badges", children: [
             item(name: "library", controller: "badges"),
             item(name: "achievements", controller: "badge_achievements"),
           ]),
      item(name: "organizations"),
      item(name: "podcasts"),
      item(name: "tags"),
    ]

    scope :customization, "tools-line", [
      item(name: "config"),
      item(name: "html variants", controller: "html_variants"),
      item(name: "display ads"),
      item(name: "navigation links"),
      item(name: "pages"),
      item(name: "profile fields", visible: false),
    ]

    scope :admin_team, "user-line", [
      item(name: "admin team", controller: "permissions"),
    ]

    scope :moderation, "shield-flash-line", [
      item(name: "reports"),
      item(name: "mods"),
      item(name: "moderator actions ads", controller: "moderator_actions"),
      item(name: "privileged reactions"),
      # item(name: "interaction limits")
    ]

    scope :advanced, "flashlight-line", [
      item(name: "broadcasts"),
      item(name: "response templates"),
      item(name: "sponsorships"),
      item(name: "developer tools", controller: "tools", children: [
             item(name: "tools"),
             item(name: "vault secrets", controller: "secrets"),
             item(name: "webhooks", controller: "webhook_endpoints"),
             item(name: "data update scripts", visible: false),
           ]),
    ]

    scope :apps, "palette-line", [
      item(name: "chat channels"),
      item(name: "consumer apps", controller: "consumer_apps"),
      item(name: "events"),
      item(name: "listings"),
      item(name: "welcome"),
    ]
  end.freeze
  # rubocop:enable Metrics/BlockLength

  def self.navigation_items
    return ITEMS unless FeatureFlag.enabled?(:profile_admin) || FeatureFlag.enabled?(:data_update_scripts)

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
