class HtmlVariantSuccessCreateJob < ApplicationJob
  queue_as :html_variant_success_create

  def perform(html_variant_id:, article_id:)
    HtmlVariantSuccess.create(html_variant_id: html_variant_id, article_id: article_id)
  end
end
