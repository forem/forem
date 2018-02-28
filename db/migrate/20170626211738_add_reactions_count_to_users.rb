class AddReactionsCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :reactions_count, :integer, null: false, default: 0
  end
end
