class AddCreatedAtIndexToFeedImportLogs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :feed_import_logs, :created_at, algorithm: :concurrently
  end
end
