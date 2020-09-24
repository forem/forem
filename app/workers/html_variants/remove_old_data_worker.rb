module HtmlVariants
  class RemoveOldDataWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 15

    def perform
      HtmlVariantTrial.delete_by("created_at < ?", 2.weeks.ago)
      HtmlVariantSuccess.delete_by("created_at < ?", 2.weeks.ago)
      HtmlVariant.find_each do |html_variant|
        html_variant.calculate_success_rate! if html_variant.html_variant_successes.any?
      end
    end
  end
end
