class AddFeedSourceToFeedImportLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :feed_import_logs, :feed_source, null: true, index: { algorithm: :concurrently }
    add_foreign_key :feed_import_logs, :feed_sources, validate: false
  end
end
