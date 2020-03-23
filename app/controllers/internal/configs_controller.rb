class Internal::ConfigsController < Internal::ApplicationController
  layout "internal"

  before_action :extra_authorization_and_confirmation, only: [:create]

  def show
    @logo_svg = SiteConfig.logo_svg.html_safe # rubocop:disable Rails/OutputSafety
  end

  def create
    clean_up_params
    config_params.keys.each do |key|
      SiteConfig.public_send("#{key}=", config_params[key].strip) unless config_params[key].nil?
    end
    bust_relevant_caches
    redirect_to internal_config_path, notice: "Site configuration was successfully updated."
  end

  private

  def config_params
    allowed_params = %i[
      default_site_email social_networks_handle mascot_user_id
      campaign_hero_html_variant_name campaign_sidebar_enabled campaign_featured_tags
      campaign_sidebar_image
      main_social_image favicon_url logo_svg logo_png primary_sticker_image_url
      rate_limit_follow_count_daily
      ga_view_id ga_fetch_rate community_description authentication_providers
      mailchimp_newsletter_id mailchimp_sustaining_members_id
      mailchimp_tag_moderators_id mailchimp_community_moderators_id
      periodic_email_digest_max periodic_email_digest_min suggested_tags
      rate_limit_comment_creation rate_limit_published_article_creation
      rate_limit_image_upload rate_limit_email_recipient sidebar_tags
    ]
    params.require(:site_config).permit(allowed_params)
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
