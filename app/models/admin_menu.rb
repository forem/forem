class AdminMenu
  # On second level navigation with more children, we reference the default tabs controller. i.e look at developer_tools
  ITEMS = Menu.define do
    scope :people, [
      item(name: "people", controller: "users"),
    ]

    scope :content_manager, [
      item(name: "posts", controller: "articles"),
      item(name: "badges", children: [
             item(name: "badge library", controller: "badges"),
             item(name: "badge achievements"),
           ]),
      item(name: "organizations"),
      item(name: "podcasts"),
      item(name: "tags"),
    ]

    scope :customization, [
      item(name: "config"),
      item(name: "HTML variants", controller: "html_variants"),
      item(name: "display_ads"),
      item(name: "navigation links"),
      item(name: "pages"),
    ]

    scope :admin_team, [
      item(name: "admin_team", controller: "permissions"),
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
      item(name: "response_templates"),
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

  def self.get_nested_menu_items(group_name, child_nav_item)
    ITEMS[group_name.to_sym].each do |items|
      return items if items[:controller] == child_nav_item

      next unless items[:children]&.any?

      items[:children].each do |child|
        return items if child[:controller] == child_nav_item
      end
    end
  end
end
