module AdminHelper
  # This is used in app/views/admin/shared/_navbar.html.erb to build the
  # side navbar in alphabetical order.
  # If you add an item before "config", please update the insert call in
  # admin_menu_items below.
  MENU_ITEMS = [
    { name: "articles",              controller: "articles" },
    { name: "broadcasts",            controller: "broadcasts" },
    { name: "badges",                controller: "badges" },
    { name: "badge_achievements",    controller: "badge_achievements" },
    { name: "chat_channels",         controller: "chat_channels" },
    { name: "comments",              controller: "comments" },
    { name: "config",                controller: "config" },
    { name: "display_ads",           controller: "display_ads" },
    { name: "events",                controller: "events" },
    { name: "html_variants",         controller: "html_variants" },
    { name: "listings",              controller: "listings" },
    { name: "moderator_actions",     controller: "moderator_actions" },
    { name: "mods",                  controller: "mods" },
    { name: "navigation_links",      controller: "navigation_links" },
    { name: "privileged_reactions",  controller: "privileged_reactions" },
    { name: "organizations",         controller: "organizations" },
    { name: "pages",                 controller: "pages" },
    { name: "permissions",           controller: "permissions" },
    { name: "podcasts",              controller: "podcasts" },
    { name: "reports",               controller: "reports" },
    { name: "response_templates",    controller: "response_templates" },
    { name: "sponsorships",          controller: "sponsorships" },
    { name: "tags",                  controller: "tags" },
    { name: "tools",                 controller: "tools" },
    { name: "users",                 controller: "users" },
    { name: "vault secrets",         controller: "secrets" },
    { name: "webhooks",              controller: "webhook_endpoints" },
    { name: "welcome",               controller: "welcome" },
  ].sort_by { |menu_item| menu_item[:name] }

  PROFILE_ADMIN = { name: "config: profile setup", controller: "profile_fields" }.freeze

  TECH_MENU_ITEMS = [
    { name: "data_update_scripts", controller: "data_update_scripts" },
  ].sort_by { |menu_item| menu_item[:name] }

  def admin_menu_items
    return MENU_ITEMS unless FeatureFlag.enabled?(:profile_admin)

    MENU_ITEMS.dup.insert(7, PROFILE_ADMIN)
  end

  # @ridhwana WIP on new admin navigation elements
  # The outer keys in NESTED_MENU_ITEMS need to correspond to the scope of the route
  # On second level navigation with more children, we reference the default tabs controller. i.e look at developer_tools
  NESTED_MENU_ITEMS = {
    overview: [{ name: "overview", controller: "" }],
    people: [{ name: "people", controller: "users" }],
    content_manager: [
      { name: "posts", controller: "articles" },
      { name: "comments", controller: "comments" },
      { name: "badges", controller: "badges", children: [
        { name: "badge library", controller: "badges" },
        { name: "badge achievements", controller: "badge_achievements" }
      ]},
      { name: "organizations", controller: "organizations" },
      { name: "podcasts", controller: "podcasts" },
      { name: "tags", controller: "tags" },
    ],
    customization: [
      { name: "config", controller: "config" },
      { name: "HTML variants", controller: "html_variants" },
      { name: "display ads", controller: "display_ads" },
      { name: "navigation links", controller: "navigation_links" },
      { name: "pages", controller: "pages" }
    ],
    admin_team: [{ name: "admin_team", controller: "permissions" }],
    moderation: [
      { name: "reports", controller: "feedback_messages" },
      { name: "mods", controller: "mods" },
      { name: "moderator actions ads", controller: "moderator_actions" },
      { name: "privileged reactions", controller: "privileged_reactions" },
      # { name: "interaction limits", controller: "" }
    ],
    advanced: [
      { name: "broadcasts", controller: "broadcasts" },
      { name: "response_templates", controller: "response_templates" },
      { name: "sponsorships", controller: "sponsorships" },
      { name: "developer tools", controller: "tools", children: [
        { name: "tools", controller: "tools" },
        { name: "vault secrets", controller: "secrets" },
        { name: "webhooks", controller: "webhook_endpoints" }
      ]}
    ],
    apps: [
      { name: "chat channels", controller: "chat_channels" },
      { name: "events", controller: "events" },
      { name: "listings", controller: "listings" },
      { name: "welcome", controller: "welcome" }
    ]
  }

  def get_nested_menu_items(group_name, child_nav_item)
    return NESTED_MENU_ITEMS[group_name.to_sym].each do |items|
      if items[:controller] == child_nav_item
        return items
      end
      if items[:children] && items[:children].length > 0
        return items[:children].each do |child|
          if child[:controller] == child_nav_item
            return items
          end
        end
      end
    end
  end
end
