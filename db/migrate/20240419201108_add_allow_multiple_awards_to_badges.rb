class AddAllowMultipleAwardsToBadges < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  
  def change
    add_column :badges, :allow_multiple_awards, :boolean, null: false, default: false

    # remove unique index
    remove_index :badge_achievements, column: [:badge_id, :user_id], algorithm: :concurrently if index_exists?(:badge_achievements, [:badge_id, :user_id])
  end
end