class Internal::PageRedirectsController < Internal::ApplicationController
  layout "internal"

  before_action :set_page_redirect, only: %i[edit update destroy]

  def new
    @page_redirect = PageRedirect.new
  end

  def create
    @page_redirect = PageRedirect.new(page_redirect_params)

    if @page_redirect.save
      flash[:success] = "Page Redirect created successfully!"
      redirect_to internal_page_redirects_path
    else
      flash[:danger] = @page_redirect.errors.full_messages.to_sentence
      render new_internal_page_redirect_path
    end
  end

  def index
    @q = PageRedirect.order(created_at: :desc).ransack(params[:q])
    @page_redirects = @q.result.page(params[:page] || 1).per(25)
  end

  def edit; end

  def update
    if @page_redirect.update(page_redirect_params.merge({ overridden: true }))
      flash[:success] = "Page Redirect updated successfully!"
      redirect_to edit_internal_page_redirect_path(@page_redirect)
    else
      flash[:danger] = @page_redirect.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    if @page_redirect.destroy
      flash[:success] = "Page Redirect destroyed successfully!"
    else
      flash[:danger] = @page_redirect.errors.full_messages.to_sentence
    end

    redirect_back(fallback_location: internal_page_redirects_path)
  end

  private

  def set_page_redirect
    @page_redirect = PageRedirect.find(params[:id])
  end

  def page_redirect_params
    params.require(:page_redirect).permit(:old_slug, :new_slug)
  end
end
