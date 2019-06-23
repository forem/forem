class HtmlVariantTrialCreateJob < ApplicationJob
  queue_as :html_variant_trial_create

  def perform(html_variant_id:, article_id:)
    HtmlVariantTrial.create!(html_variant_id: html_variant_id, article_id: article_id)
  end
end
