class HtmlVariantSuccessesController < ApplicationMetalController
  include ActionController::Head

  def create
    HtmlVariantSuccessCreateWorker.perform_async(params[:html_variant_id], params[:article_id])
    head :ok
  end
end
