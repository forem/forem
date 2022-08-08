module Admin
  class NavigationLinksController < Admin::ApplicationController
    after_action :bust_content_change_caches, only: %i[create update destroy]
    ALLOWED_PARAMS = %i[
      name url icon display_to position section
    ].freeze
    layout "admin"

    def index
      @default_nav_links = NavigationLink.default_section.ordered
      @other_nav_links = NavigationLink.other_section.ordered
    end

    def create
      navigation_link = NavigationLink.new(navigation_link_params)
      if navigation_link.save
        flash[:success] =
          I18n.t("admin.navigation_links_controller.created",
                 link: navigation_link.name)
      else
        flash[:error] = I18n.t("errors.messages.general", errors: navigation_link.errors_as_sentence)
      end
      redirect_to admin_navigation_links_path
    end

    def update
      navigation_link = NavigationLink.find(params[:id])
      if navigation_link.update(navigation_link_params)
        flash[:success] =
          I18n.t("admin.navigation_links_controller.updated",
                 link: navigation_link.name)
      else
        flash[:error] = I18n.t("errors.messages.general", errors: navigation_link.errors_as_sentence)
      end
      redirect_to admin_navigation_links_path
    end

    def destroy
      navigation_link = NavigationLink.find(params[:id])
      if navigation_link.destroy
        flash[:success] =
          I18n.t("admin.navigation_links_controller.deleted",
                 link: navigation_link.name)
      else
        flash[:error] = I18n.t("errors.messages.general", errors: navigation_link.errors_as_sentence)
      end
      redirect_to admin_navigation_links_path
    end

    private

    def navigation_link_params
      params.require(:navigation_link).permit(ALLOWED_PARAMS)
    end
  end
end
