class Internal::ConfigsController < Internal::ApplicationController
  layout "internal"

  def show
    @logo_svg = SiteConfig.logo_svg.html_safe # rubocop:disable Rails/OutputSafety
  end

  def create
    config_params.keys.each do |key|
      SiteConfig.public_send("#{key}=", config_params[key].strip) unless config_params[key].nil?
    end
    redirect_to internal_config_path, notice: "Site configuration was successfully updated."
  end

  private

  def config_params
    allowed_params = %i[
      staff_user_id default_site_email social_networks_handle
      main_social_image favicon_url logo_svg
      rate_limit_follow_count_daily
      ga_view_id ga_fetch_rate
      mailchimp_newsletter_id mailchimp_sustaining_members_id
      mailchimp_tag_moderators_id mailchimp_community_moderators_id
      periodic_email_digest_max periodic_email_digest_min
    ]
    params.require(:site_config).permit(allowed_params)
  end
end
