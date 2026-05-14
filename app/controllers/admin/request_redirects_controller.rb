class Admin::RequestRedirectsController < Admin::ApplicationController
  before_action :set_request_redirect, only: %i[show edit update destroy]

  def index
    @request_redirects = RequestRedirect.order(created_at: :desc).page(params[:page]).per(50)
  end

  def show
  end

  def new
    @request_redirect = RequestRedirect.new
  end

  def edit
  end

  def create
    @request_redirect = RequestRedirect.new(request_redirect_params)

    if @request_redirect.save
      redirect_to admin_request_redirects_path, notice: "Request redirect was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @request_redirect.update(request_redirect_params)
      redirect_to admin_request_redirects_path, notice: "Request redirect was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @request_redirect.destroy
    redirect_to admin_request_redirects_path, notice: "Request redirect was successfully destroyed."
  end

  private

  def set_request_redirect
    @request_redirect = RequestRedirect.find(params[:id])
  end

  def request_redirect_params
    params.require(:request_redirect).permit(:original_url, :destination_url, :request_domain)
  end
end
