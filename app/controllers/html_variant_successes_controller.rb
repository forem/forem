class HtmlVariantSuccessesController < ApplicationController
  def create
    HtmlVariantSuccess.delay.create(html_variant_id: params[:html_variant_id], article_id: params[:article_id])
    head :ok
  end
end
