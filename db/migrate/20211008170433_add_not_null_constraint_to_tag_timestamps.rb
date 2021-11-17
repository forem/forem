class AddNotNullConstraintToTagTimestamps < ActiveRecord::Migration[6.1]
  # Timestamps were added to acts_as_taggable_on at this time
  # See: https://github.com/mbleigh/acts-as-taggable-on/commit/ce14b9ead3a283577a976b6b0d9bfbec278e21bb
  DEFAULT_TIMESTAMP = "2019-02-06 16:43:19"

  def up
    # This migration will lock the table, so StrongMigrations is right to call
    # it out, but this particular table isn't so large that a table lock will
    # cause downtime. The EXPLAIN ANALYZE on the query that will be used to
    # check this on DEV shows "Execution Time: 34.136 ms". We can handle a 34ms
    # table lock.
    StrongMigrations.temporarily_disable_check :change_column_null_postgresql do
      Tag
        .where(created_at: nil)
        .update_all(created_at: DEFAULT_TIMESTAMP)

      Tag
        .where(updated_at: nil)
        .update_all(updated_at: DEFAULT_TIMESTAMP)

      change_column_null :tags, :created_at, false
      change_column_null :tags, :updated_at, false
    end
  end

  def down
    StrongMigrations.temporarily_disable_check :change_column_null_postgresql do
      change_column_null :tags, :created_at, true
      change_column_null :tags, :updated_at, true
    end
  end
end
