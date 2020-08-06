module Admin
  class PagesController < Admin::ApplicationController
    layout "admin"

    def index
      @pages = Page.all
    end

    def new
      @page = Page.new
    end

    def edit
      @page = Page.find(params[:id])
    end

    def update
      @page = Page.find(params[:id])
      @page.update!(page_params)
      redirect_to "/admin/pages"
    end

    def create
      @page = Page.new(page_params)
      @page.save!
      redirect_to "/admin/pages"
    end

    def destroy
      @page = Page.find(params[:id])
      @page.destroy
      redirect_to "/admin/pages"
    end

    private

    def page_params
      allowed_params = %i[title slug body_markdown body_html body_json description template is_top_level_path
                          social_image]
      params.require(:page).permit(allowed_params)
    end
  end
end
