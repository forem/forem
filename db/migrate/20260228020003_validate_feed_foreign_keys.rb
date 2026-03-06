class ValidateFeedForeignKeys < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :feed_sources, :users, column: :author_user_id
    validate_foreign_key :feed_import_logs, :feed_sources
  end
end
