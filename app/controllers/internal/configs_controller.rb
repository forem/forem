class Internal::ConfigsController < Internal::ApplicationController
  layout "internal"

  def show; end

  def create
    config_params.keys.each do |key|
      SiteConfig.public_send("#{key}=", config_params[key].strip) unless config_params[key].nil?
    end
    redirect_to internal_config_path, notice: "Site configuration was successfully updated."
  end

  private

  def config_params
    allowed_params = %i[main_social_image favicon_url rate_limit_follow_count_daily]
    params.require(:site_config).permit(allowed_params)
  end
end
