class AddCurrentSubscriberStatusToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :users, :current_subscriber_status, :integer, default: 0, null: false
    add_index :users, :current_subscriber_status, algorithm: :concurrently
  end
end
