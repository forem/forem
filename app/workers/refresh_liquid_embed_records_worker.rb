class RefreshLiquidEmbedRecordsWorker
  include Sidekiq::Job

  sidekiq_options queue: :low_priority, retry: 5

  ALLOWED_RECORD_TYPES = %w[Article Comment Page Billboard].freeze

  # Re-renders stored processed_html (and busts caches when it changed) for records that embed liquid tags.
  def perform(record_type, record_ids)
    return unless ALLOWED_RECORD_TYPES.include?(record_type)

    Articles::UpdateDependentEmbedsWorker.new.refresh_records(record_type, Array(record_ids))
  end
end
