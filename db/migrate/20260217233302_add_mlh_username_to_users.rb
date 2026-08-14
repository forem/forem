class AddMlhUsernameToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :users, :mlh_username, :string
    add_index :users, :mlh_username, algorithm: :concurrently
  end
end
