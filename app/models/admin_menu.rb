class AdminMenu
  # On second level navigation with more children, we reference the default tabs controller. i.e look at developer_tools
  # rubocop:disable Metrics/BlockLength
  ITEMS = Menu.define do
    scope :people, [
      item(name: "people", controller: "users"),
    ]

    scope :content_manager, [
      item(name: "posts", controller: "articles"),
      item(name: "badges", children: [
             item(name: "library", controller: "badges"),
             item(name: "achievements", controller: "badge_achievements"),
           ]),
      item(name: "organizations"),
      item(name: "podcasts"),
      item(name: "tags"),
    ]

    scope :customization, [
      item(name: "config"),
      item(name: "html variants", controller: "html_variants"),
      item(name: "display ads"),
      item(name: "navigation links"),
      item(name: "pages"),
    ]

    scope :admin_team, [
      item(name: "admin team", controller: "permissions"),
    ]

    scope :moderation, [
      item(name: "reports"),
      item(name: "mods"),
      item(name: "moderator actions ads", controller: "moderator_actions"),
      item(name: "privileged reactions"),
      # item(name: "interaction limits", controller: "" )
    ]

    scope :advanced, [
      item(name: "broadcasts"),
      item(name: "response templates"),
      item(name: "sponsorships"),
      item(name: "developer tools", controller: "tools", children: [
             item(name: "tools"),
             item(name: "vault secrets", controller: "secrets"),
             item(name: "webhooks", controller: "webhook_endpoints"),
           ]),
    ]

    scope :apps, [
      item(name: "chat channels"),
      item(name: "events"),
      item(name: "listings"),
      item(name: "welcome"),
    ]
  end
  # rubocop:enable Metrics/BlockLength

  def self.nested_menu_items(group_name, child_nav_item)
    ITEMS[group_name.to_sym].each do |items|
      return items if items[:controller] == child_nav_item

      next unless items[:children]&.any?

      items[:children].each do |child|
        return items if child[:controller] == child_nav_item
      end
    end
  end

  def self.nested_menu_items_from_request(request)
    group, child_nav_item = request.path.split("/").last(2)
    nested_menu_items(group, child_nav_item)
  end
end
