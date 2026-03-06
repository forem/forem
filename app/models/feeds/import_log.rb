module Feeds
  class ImportLog < ApplicationRecord
    self.table_name = "feed_import_logs"

    include Feeds::Stateful

    belongs_to :user
    belongs_to :feed_source, class_name: "Feeds::Source", optional: true
    has_many :import_items, class_name: "Feeds::ImportItem", foreign_key: :feed_import_log_id,
                            inverse_of: :import_log, dependent: :delete_all

    enum status: { pending: 0, fetching: 1, parsing: 2, importing: 3, completed: 4, failed: 5 }

    scope :recent, -> { order(created_at: :desc) }
    scope :for_cleanup, -> { where(created_at: ...30.days.ago) }
    scope :for_feed_source, ->(feed_source_id) { where(feed_source_id: feed_source_id) }
    scope :notable, -> { where("items_imported > 0 OR items_failed > 0 OR status = ?", statuses[:failed]) }
    scope :routine, -> { where(status: :completed).where(items_imported: 0, items_failed: 0) }

    def routine_check?
      completed? && items_imported.zero? && items_failed.zero?
    end

    def feed_source_name
      feed_source&.name || feed_source&.feed_url || feed_url
    end
  end
end
