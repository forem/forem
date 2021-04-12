module FeatureFlagUrlHelper
  # class Something
  # [@ridhwana] this is a ridiculous but temporary solution that overrides each helper
  # method being used in the admin view to point to a new helper method
  # (when the Feeature Flag is toggled).
  # For more details about why this exists please read https://github.com/forem/forem/pull/13114#issuecomment-814788111
  # This hacky solution will most likely only live a week after it's merged.
  # The file will be deleted along with the old code, old routes and admin_restructure
  # feature flag, once we've tested the new route structure.
  # the as option will be removed in the routes/admin.rb

  # VERY WIP unpolished code but commiting it be transparent about my thinking and research as I try adn solve this problem..

  @CONTENT_MANAGER = %w(articles article badges badge edit_badge new_badge badge_achievements badge_achievement badge_achievements_award_badges comments organizations organization podcasts podcast fetch_podcast edit_podcast new_podcast tags tag edit_tag new_tag tag_moderator)
  @CUSTOMIZATION = %w(config display_ads display_ad edit_display_ad new_display_ad html_variants html_variant edit_html_variant new_html_variant navigation_links navigation_link edit_navigation_link new_navigation_link pages page edit_page new_page profile_fields profile_field edit_profile_field new_profile_field profile_field_groups profile_field_group edit_profile_field_groups new_profile_field_groups)
  @MODERATION = %w(reports report feedback_messages feedback_message mods edit_mod moderator_actions privileged_reactions)
  @ADVANCED = %w(broadcasts broadcast edit_broadcast new_broadcast response_templates response_template edit_response_template new_response_template secrets sponsorships sponsorship edit_sponsorship new_sponsorship tools new_tool webhook_endpoints data_update_scripts data_update_script)
  # put secrets

  @APPS = %w(chat_channels edit_chat_channel new_chat_channel events edit_event new_event listings edit_listing new_listing listing_categories listing_categories edit_listing_categories new_listing_categories welcome_index )

  SCOPES = %w(content_manager customization moderation advanced apps).freeze


  SCOPES.each do |scope|
    instance_variable_get("@#{scope.upcase}").each do |helper_name|
      if FeatureFlag.enabled?(:admin_restructure)
        if helper_name.include?("edit") || helper_name.include?("new") || helper_name.include?("destroy") || helper_name.include?("fetch")
          resource_type = helper_name.split("_")[0]
          resource_name = helper_name.remove("#{resource_type}_")

          define_method("#{resource_type}_admin_#{resource_name}_path") do |*args|
            send("#{resource_type}_admin_#{scope}_#{resource_name}_path".to_sym, *args)
          end
        else
          define_method("admin_#{helper_name}_path") do |*args|
            send("admin_#{scope}_#{helper_name}_path".to_sym, *args)
          end
        end
      end
    end
  end


  def update_org_credits_admin_organization_path(*args)
    send("update_org_credits_admin_content_manager_organization_path".to_sym, *args)
  end

  def add_owner_admin_podcast_path(*args)
    send("add_owner_admin_content_manager_podcast_path".to_sym, *args)
  end

  def bust_cache_admin_tools_path(*args)
    send("bust_cache_admin_advanced_tools_path".to_sym, *args)
  end

end
