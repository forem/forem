class Internal::PageRedirectsController < Internal::ApplicationController
  layout "internal"

  def index
    @page_redirects = PageRedirect

    if params[:search].present?
      @page_redirects = @page_redirects.where("page_redirects.old_slug ILIKE :search OR
                                               page_redirects.new_slug ILIKE :search",
                                              search: "%#{params[:search]}%")
    end

    @page_redirects = @page_redirects.order(created_at: :desc).page(params[:page] || 1).per(50)
  end
end
