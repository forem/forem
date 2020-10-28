module Admin
  class ApplicationController < ApplicationController
    before_action :authorize_admin
    after_action :verify_authorized

    # This is used in app/views/admin/shared/_navbar.html.erb to build the
    # side navbar in alphabetical order.
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
      { name: "growth",                controller: "growth" },
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
    ].sort_by { |menu_item| menu_item[:name] }.freeze

    private

    def authorization_resource
      self.class.name.demodulize.sub("Controller", "").singularize.constantize
    end

    def authorize_admin
      authorize(authorization_resource, :access?, policy_class: InternalPolicy)
    end

    def bust_content_change_caches
      CacheBuster.bust("/tags/onboarding") # Needs to change when suggested_tags is edited.
      CacheBuster.bust("/shell_top") # Cached at edge, sent to service worker.
      CacheBuster.bust("/shell_bottom") # Cached at edge, sent to service worker.
      CacheBuster.bust("/onboarding") # Page is cached at edge.
      CacheBuster.bust("/") # Page is cached at edge.
      SiteConfig.admin_action_taken_at = Time.current # Used as cache key
    end
  end
end
