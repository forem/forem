module Admin
  class NavigationLinksController < Admin::ApplicationController
    ALLOWED_PARAMS = %i[
      name url icon requires_auth
    ].freeze
    layout "admin"

    def index
      @navigation_links = NavigationLink.all.order(:name)
    end

    def create
      navigation_link = NavigationLink.new(navigation_link_params)
      if navigation_link.save
        flash[:success] = "Successfully created navigation link: #{navigation_link.name}"
      else
        flash[:error] = "Error: #{navigation_link.errors_as_sentence}"
      end
      redirect_to admin_navigation_links_url
    end

    def update
      navigation_link = NavigationLink.find(params[:id])
      if navigation_link.update(navigation_link_params)
        flash[:success] = "Successfully updated navigation link: #{navigation_link.name}"
      else
        flash[:error] = "Error: #{navigation_link.errors_as_sentence}"
      end
      redirect_to admin_navigation_links_url
    end

    def destroy
      navigation_link = NavigationLink.find(params[:id])
      if navigation_link.destroy
        flash[:success] = "Navigation Link #{navigation_link.name} deleted"
      else
        flash[:error] = "Error: #{navigation_link.errors_as_sentence}"
      end
      redirect_to admin_navigation_links_url
    end

    private

    def navigation_link_params
      allowed_params = ALLOWED_PARAMS
      params.require(:navigation_link).permit(allowed_params)
    end
  end
end
