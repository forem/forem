class HtmlVariantTrialsController < ApplicationController
  def create
    HtmlVariantTrial.create!(html_variant_id: params[:html_variant_id])
    head :ok
  end
end
