class Internal::PageRedirectsController < Internal::ApplicationController
  layout "internal"

  def index
    @q = PageRedirect.order(created_at: :desc).ransack(params[:q])
    @page_redirects = @q.result.page(params[:page] || 1).per(25)
  end
end
