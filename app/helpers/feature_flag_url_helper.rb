module FeatureFlagUrlHelper
  # [@ridhwana] this is a ridiculous but temporary solution that overrides each helper
  # method being used in the admin view to point to a new helper method
  # (when the Feeature Flag is toggled).
  # For more details about why this exists please read https://github.com/forem/forem/pull/13114#issuecomment-814788111
  # This hacky solution will most likely only live a week after it's merged.
  # The file will be deleted along with the old code, old routes and admin_restructure
  # feature flag, once we've tested the new route structure.
  # the as option will be removed in the routes/admin.rb

  # VERY WIP unpolished code but commiting it be transparent about my thinking and research as I try adn solve this problem..
    ["tags", "articles", "article", "badges", "badge", "edit_badge"].each do |helper_name|
      if FeatureFlag.enabled?(:admin_restructure)
        if helper_name.include?('edit') || helper_name.include?('new')
          define_method("#{helper_name.split("_")[0]}_admin_#{helper_name.split("_")[1]}_path") do |*args|
            send("#{helper_name.split("_")[0]}_admin_content_manager_#{helper_name.split("_")[1]}_path".to_sym, *args)
          end
        else
          define_method("admin_#{helper_name}_path") do |*args|
            send("admin_content_manager_#{helper_name}_path".to_sym, *args)
          end
        end
      end
    end

    # ["pages", "config", "navigation_links"].each do |helper_name|
    #   if FeatureFlag.enabled?(:admin_restructure)
    #     define_method("admin_#{helper_name}_path") do |*args|
    #       puts "admin_customization_#{helper_name}_path"
    #       send "admin_customization_#{helper_name}_path".to_sym
    #     end
    #   end
    # end
end

# module FeatureFlagUrlHelper
#   def admin_tags_path(**kwargs)
#     return index_path("content_manager", "tags", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_articles_path(**kwargs)
#     return index_path("content_manager", "articles", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_article_path(id, **kwargs)
#     return show_path("content_manager", "articles", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_config_path(**kwargs)
#     return index_path("customization", "config", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_pages_path(**kwargs)
#     return index_path("customization", "pages", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_navigation_links_path(**kwargs)
#     return index_path("customization", "navigation_links", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_welcome_index_path(**kwargs)
#     return index_path("apps", "welcome", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_badges_path(**kwargs)
#     return index_path("content_manager", "badges", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def new_admin_badge_path(**kwargs)
#     return d_new_path("content_manager", "badges", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def edit_admin_badge_path(id, **kwargs)
#     return edit_path("content_manager", "badges", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_badge_achievements_path(**kwargs)
#     return index_path("content_manager", "badge_achievements", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_badge_achievements_award_badges_path(**kwargs)
#     if FeatureFlag.enabled?(:admin_restructure)
#       return determine_admin_badge_achievements_award_badges_path("content_manager", "badge_achievements",
#                                                                   kwargs)
#     end
#
#     super
#   end
#
#   def admin_broadcasts_path(**kwargs)
#     return index_path("advanced", "broadcasts", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def new_admin_broadcast_path(**kwargs)
#     return d_new_path("advanced", "badges", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_broadcast_path(id, **kwargs)
#     return index_path("advanced", "badges", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def edit_admin_broadcast_path(id, **kwargs)
#     return edit_path("advanced", "badges", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_display_ad_path(id, **kwargs)
#     return show_path("customization", "display_ads", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def new_admin_display_ad_path(**kwargs)
#     return d_new_path("customization", "display_ads", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def edit_admin_display_ad_path(id, **kwargs)
#     return edit_path("customization", "display_ads", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_organization_path(id, **kwargs)
#     return show_path("content_manager", "organizations", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_report_path(id, **kwargs)
#     return show_path("moderation", "reports", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def new_admin_event_path(**kwargs)
#     return d_new_path("apps", "events", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def edit_admin_event_path(id, **kwargs)
#     return edit_path("apps", "events", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_html_variants_path(**kwargs)
#     return index_path("customization", "html_variants", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def admin_html_variant_path(id, **kwargs)
#     return show_path("customization", "html_variants", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def edit_admin_html_variant_path(id, **kwargs)
#     return show_path("customization", "html_variants", id, kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
#
#   def new_admin_html_variant_path(**kwargs)
#     return d_new_path("customization", "html_variants", kwargs) if FeatureFlag.enabled?(:admin_restructure)
#
#     super
#   end
# end
#
# private
#
# def index_path(scope, resource, kwargs)
#   str = "/admin/#{scope}/#{resource}"
#   unless kwargs.empty?
#     str += "?#{kwargs.map { |k, v| "#{k}=#{v}" }.join('&')}"
#   end
#
#   str
# end
#
# def show_path(scope, resource, id, kwargs)
#   str = "/admin/#{scope}/#{resource}/#{id}"
#   unless kwargs.empty?
#     str += "?#{kwargs.map { |k, v| "#{k}=#{v}" }.join('&')}"
#   end
#
#   str
# end
#
# def d_new_path(scope, resource, kwargs)
#   str = "/admin/#{scope}/#{resource}/new"
#   unless kwargs.empty?
#     str += "?#{kwargs.map { |k, v| "#{k}=#{v}" }.join('&')}"
#   end
#
#   str
# end
#
# def edit_path(scope, resource, id, kwargs)
#   str = "/admin/#{scope}/#{resource}/#{id}/edit"
#   unless kwargs.empty?
#     str += "?#{kwargs.map { |k, v| "#{k}=#{v}" }.join('&')}"
#   end
#
#   str
# end
#
# def determine_admin_badge_achievements_award_badges_path(scope, resource, kwargs)
#   str = "/admin/#{scope}/#{resource}/award_badges"
#   unless kwargs.empty?
#     str += "?#{kwargs.map { |k, v| "#{k}=#{v}" }.join('&')}"
#   end
#
#   str
# end
