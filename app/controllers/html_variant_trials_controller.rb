class HtmlVariantTrialsController < ApplicationMetalController
  include ActionController::Head

  def create
    HtmlVariantTrialCreateJob.perform_later(html_variant_id: params[:html_variant_id], article_id: params[:article_id])
    head :ok
  end
end
