class HtmlVariantSuccessCreateWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 10

  def perform(html_variant_id, article_id)
    HtmlVariantSuccess.create(html_variant_id: html_variant_id, article_id: article_id)
  end
end
