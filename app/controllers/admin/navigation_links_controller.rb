module Admin
  class NavigationLinksController < Admin::ApplicationController
    layout "admin"

    def index
      @navigation_links = SiteConfig.navigation
    end

    def create
      return if config_params["navigation"].blank?

      new_links = config_params["navigation"]
      validation = SiteConfigs::ValidateNavigation.call(new_links)
      if validation.success?
        update_navigation_links = SiteConfig.navigation + new_links
        SiteConfig.navigation = update_navigation_links

        flash[:notice] = "Navigation Link #{config_params['navigation'][0]['name']} was successfully added."
      else
        flash[:danger] = "Navigation Links error: #{validation.errors[0].join(' , ')}"
      end
      redirect_to admin_navigation_links_url
    end

    def destroy
      navigation_links = SiteConfig.navigation
      updated_navigation_links = navigation_links.reject { |link| link[:name] == params[:id] }
      SiteConfig.navigation = updated_navigation_links

      # how would this fail?
      flash[:success] = "Navigation Link #{params[:id]} deleted"
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
