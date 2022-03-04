class AddBlockedCountToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :blocked_by_count, :bigint, null: false, default: 0
    add_column :users, :blocking_others_count, :bigint, null: false, default: 0
  end
end
