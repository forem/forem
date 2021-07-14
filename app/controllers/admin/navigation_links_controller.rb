module Admin
  class NavigationLinksController < Admin::ApplicationController
    after_action :bust_content_change_caches, only: %i[create update destroy]
    ALLOWED_PARAMS = %i[
      name url icon display_only_when_signed_in position section
    ].freeze
    layout "admin"

    def index
      @navigation_links = NavigationLink.ordered
    end

    def create
      navigation_link = NavigationLink.new(navigation_link_params)
      if navigation_link.save
        flash[:success] = "Successfully created navigation link: #{navigation_link.name}"
      else
        flash[:error] = "Error: #{navigation_link.errors_as_sentence}"
      end
      redirect_to admin_navigation_links_path
    end

    def update
      navigation_link = NavigationLink.find(params[:id])
      if navigation_link.update(navigation_link_params)
        flash[:success] = "Successfully updated navigation link: #{navigation_link.name}"
      else
        flash[:error] = "Error: #{navigation_link.errors_as_sentence}"
      end
      redirect_to admin_navigation_links_path
    end

    def destroy
      navigation_link = NavigationLink.find(params[:id])
      if navigation_link.destroy
        flash[:success] = "Navigation Link #{navigation_link.name} deleted"
      else
        flash[:error] = "Error: #{navigation_link.errors_as_sentence}"
      end
      redirect_to admin_navigation_links_path
    end

    private

    def navigation_link_params
      params.require(:navigation_link).permit(ALLOWED_PARAMS)
    end
  end
end
