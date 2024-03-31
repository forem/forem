module Admin
  class ApplicationController < ApplicationController
    before_action :authorize_admin
    before_action :assign_help_url
    after_action :verify_authorized

    HELP_URLS = {
      articles: "https://admin.forem.com/docs/forem-basics/posts",
      badges: "https://admin.forem.com/docs/forem-basics/badges",
      badge_achievements: "https://admin.forem.com/docs/forem-basics/badges",
      billboards: "https://admin.forem.com/docs/advanced-customization/billboards",
      feedback_messages: "https://admin.forem.com/docs/advanced-customization/reports",
      html_variants: "https://admin.forem.com/docs/advanced-customization/html-variants",
      navigation_links: "https://admin.forem.com/docs/advanced-customization/navigation-links",
      organizations: "https://admin.forem.com/docs/managing-your-community/organization-pages",
      pages: "https://admin.forem.com/docs/forem-basics/pages",
      permissions: "https://admin.forem.com/docs/forem-basics/user-roles",
      podcasts: "https://admin.forem.com/docs/advanced-customization/content-manager/podcasts",
      settings: "https://admin.forem.com/docs/advanced-customization/config",
      tags: "https://admin.forem.com/docs/forem-basics/tags",
      users: "https://admin.forem.com/docs/forem-basics/user-roles",
      creator_settings: "https://admin.forem.com/docs/getting-started/first-user-registration"
    }.freeze

    protected

    def authorization_resource
      self.class.name.sub("Admin::", "").sub("Controller", "").singularize.constantize
    end

    def authorize_admin
      authorize(authorization_resource, :access?, policy_class: InternalPolicy)
    end

    def assign_help_url
      @help_url = HELP_URLS[controller_name.to_sym]
    end
  end
end
