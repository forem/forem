class RerenderCommentEmbedsWorker
  include Sidekiq::Job

  sidekiq_options queue: :low_priority, retry: 5

  # Comments go first: comments/_liquid renders the embedded comment's stored HTML, so a comment that
  # embeds another comment must be re-rendered before the articles, pages and billboards that embed it.
  RECORD_TYPES = %w[Comment Article Page Billboard].freeze
  EMBED_MARKER = "%ltag__comment%".freeze
  HTML_CONDITIONS = Hash.new("processed_html LIKE :marker").merge(
    "Billboard" => "processed_html LIKE :marker OR minimized_processed_html LIKE :marker",
  ).freeze
  RANGE_SIZE = 2_000
  DELAY = 2.seconds

  sidekiq_retries_exhausted do |job, exception|
    record_type, start_id = job["args"]
    Rails.logger.error(
      "[RerenderCommentEmbedsWorker] Giving up on #{record_type} ids #{start_id}...#{start_id.to_i + RANGE_SIZE}: " \
      "#{exception.class} - #{exception.message}",
    )
    enqueue_next(record_type, start_id.to_i + RANGE_SIZE)
  end

  # Walks one record type in id order, then moves to the next type, keeping a single job in flight.
  def self.enqueue_next(record_type, from_id)
    next_id = record_type.constantize.where(id: from_id..).minimum(:id)
    return perform_in(DELAY, record_type, next_id) if next_id

    next_type = RECORD_TYPES[RECORD_TYPES.index(record_type) + 1]
    perform_in(DELAY, next_type, 0) if next_type
  end

  # Re-renders stored HTML that contains a comment embed for one bounded id range. Finding embeds by their
  # rendered markup also reaches records saved before liquid_embed_references existed.
  def perform(record_type, start_id = 0)
    return unless RECORD_TYPES.include?(record_type)

    end_id = start_id + RANGE_SIZE
    ids = record_type.constantize
      .where(id: start_id...end_id)
      .where(HTML_CONDITIONS[record_type], marker: EMBED_MARKER)
      .ids
    Articles::UpdateDependentEmbedsWorker.new.refresh_records(record_type, ids)
    self.class.enqueue_next(record_type, end_id)
  end
end
