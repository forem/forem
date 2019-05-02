class Internal::PagesController < Internal::ApplicationController
  layout "internal"

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
    redirect_to "/internal/pages"
  end

  def create
    @page = Page.new(page_params)
    @page.save!
    redirect_to "/internal/pages"
  end

  def destroy
    @page = Page.find(params[:id])
    @page.destroy
    redirect_to "/internal/pages"
  end

  def page_params
    params.require(:page).permit(:title,
                                 :slug,
                                 :body_markdown,
                                 :body_html,
                                 :description,
                                 :template)
  end
end
