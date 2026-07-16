class SetupVectorColumnsForFeed < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    if column_exists?(:user_activities, :semantic_interest_profile)
      # This column was added in an earlier PR but never populated in production.
      # It is safe to remove unconditionally.
      safety_assured do
        remove_column :user_activities, :semantic_interest_profile
      end
    end
    add_column :user_activities, :interest_embedding, :vector, limit: 768
    add_column :articles, :semantic_embedding, :vector, limit: 768
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Rollback is data-destructive: dropped interest and semantic embeddings cannot be restored."
  end
end
