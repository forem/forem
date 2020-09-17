class AddReactionsCountToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :reactions_count, :integer, null: false, default: 0
  end
end
