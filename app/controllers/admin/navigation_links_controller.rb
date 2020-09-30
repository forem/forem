module Admin
  class NavigationLinksController < Admin::ApplicationController
    layout "admin"

    def index
      @navigation_links = SiteConfig.navigation
    end

    def create
      return if config_params["navigation"].blank?

      update_navigation_links = SiteConfigs::UpdateNavigation.call(config_params["navigation"])
      if SiteConfigs::UpdateNavigation.call(config_params["navigation"]).success?
        flash[:notice] = "Navigation Link #{config_params['navigation'][0]['name']} was successfully added."
      else
        flash[:danger] = "Navigation Links error: #{update_navigation_links.errors[0].join(' , ')}"
      end
      redirect_to admin_navigation_links_url
    end

    private

    def config_params
      params.require(:site_config).permit(
        navigation: %i[name url icon],
      )
    end
  end
end
