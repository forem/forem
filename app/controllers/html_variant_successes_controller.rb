class HtmlVariantSuccessesController < ApplicationMetalController
  include ActionController::Head

  def create
    HtmlVariantSuccessCreateJob.perform_later(html_variant_id: params[:html_variant_id], article_id: params[:article_id])
    head :ok
  end
end
