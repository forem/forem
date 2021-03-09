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
    ]

    scope :admin_team, "user-line", [
      item(name: "admin team", controller: "permissions"),
    ]

    scope :moderation, "shield-flash-line", [
      item(name: "reports"),
      item(name: "mods"),
      item(name: "moderator actions ads", controller: "moderator_actions"),
      item(name: "privileged reactions"),
      # item(name: "interaction limits", controller: "" )
    ]

    scope :advanced, "flashlight-line", [
      item(name: "broadcasts"),
      item(name: "response templates"),
      item(name: "sponsorships"),
      item(name: "developer tools", controller: "tools", children: [
             item(name: "tools"),
             item(name: "vault secrets", controller: "secrets"),
             item(name: "webhooks", controller: "webhook_endpoints"),
           ]),
    ]

    scope :apps, "palette-line", [
      item(name: "chat channels"),
      item(name: "events"),
      item(name: "listings"),
      item(name: "welcome"),
    ]
  end
  # rubocop:enable Metrics/BlockLength

  def self.nested_menu_items(scope_name, nav_item)
    ITEMS.dig(scope_name.to_sym, :children).each do |items|
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
end
