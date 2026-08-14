class Api::V1::Admin::RequestRedirectsController < Api::V1::Admin::BaseController
  before_action :set_request_redirect, only: %i[show update destroy]

  def index
    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = [params.fetch(:per_page, 50).to_i, 100].min

    @request_redirects = RequestRedirect.order(created_at: :desc).page(page).per(per_page)
    render json: @request_redirects
  end

  def show
    render json: @request_redirect
  end

  def create
    @request_redirect = RequestRedirect.new(request_redirect_params)

    if @request_redirect.save
      render json: @request_redirect, status: :created
    else
      render json: { errors: @request_redirect.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @request_redirect.update(request_redirect_params)
      render json: @request_redirect
    else
      render json: { errors: @request_redirect.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @request_redirect.destroy
    head :no_content
  end

  private

  def set_request_redirect
    @request_redirect = RequestRedirect.find(params[:id])
  end

  def request_redirect_params
    params.require(:request_redirect).permit(:original_url, :destination_url, :request_domain)
  end
end
