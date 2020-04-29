class Internal::ConfigsController < Internal::ApplicationController
  layout "internal"

  before_action :extra_authorization_and_confirmation, only: [:create]

  def show
    @logo_svg = SiteConfig.logo_svg.html_safe # rubocop:disable Rails/OutputSafety
  end

  def create
    clean_up_params

    config_params.each do |key, value|
      if value.respond_to?(:to_h)
        SiteConfig.public_send("#{key}=", value.to_h) unless value.empty?
      else
        SiteConfig.public_send("#{key}=", value.strip) unless value.nil?
      end
    end

    bust_relevant_caches
    redirect_to internal_config_path, notice: "Site configuration was successfully updated."
  end

  private

  def config_params
    allowed_params = %i[
      authentication_providers
      campaign_featured_tags
      campaign_hero_html_variant_name
      campaign_sidebar_enabled
      campaign_sidebar_image
      community_description
      community_member_description
      community_member_label
      tagline
      favicon_url
      ga_view_id ga_fetch_rate
      logo_png
      logo_svg
      mailchimp_community_moderators_id
      mailchimp_newsletter_id
      mailchimp_sustaining_members_id
      mailchimp_tag_moderators_id
      main_social_image
      mascot_image_description
      mascot_image_url
      mascot_user_id
      onboarding_taskcard_image
      periodic_email_digest_max
      periodic_email_digest_min
      primary_sticker_image_url
      rate_limit_comment_creation
      rate_limit_email_recipient
      rate_limit_follow_count_daily
      rate_limit_image_upload
      rate_limit_published_article_creation
      shop_url
      sidebar_tags
      suggested_tags
    ]
    params.require(:site_config).permit(allowed_params, social_media_handles: SiteConfig.social_media_handles.keys, email_addresses: SiteConfig.email_addresses.keys)
  end

  def extra_authorization_and_confirmation
    not_authorized unless current_user.has_role?(:single_resource_admin, Config) # Special additional permission
    not_authorized if params[:confirmation] != "My username is @#{current_user.username} and this action is 100% safe and appropriate."
  end

  def clean_up_params
    config = params[:site_config]
    config[:suggested_tags] = config[:suggested_tags].downcase.delete(" ") if config[:suggested_tags]
    config[:authentication_providers] = config[:authentication_providers].downcase.delete(" ") if config[:authentication_providers]
    config[:sidebar_tags] = config[:sidebar_tags].downcase.delete(" ") if config[:sidebar_tags]
  end

  def bust_relevant_caches
    CacheBuster.bust("/tags/onboarding") # Needs to change when suggested_tags is edited
  end
end
