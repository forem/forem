module Feeds
  class ImportItem < ApplicationRecord
    self.table_name = "feed_import_items"

    belongs_to :import_log, class_name: "Feeds::ImportLog", foreign_key: :feed_import_log_id,
                            inverse_of: :import_items
    belongs_to :article, optional: true

    enum status: { imported: 0, skipped_duplicate: 1, skipped_medium_reply: 2, failed: 3 }
  end
end
