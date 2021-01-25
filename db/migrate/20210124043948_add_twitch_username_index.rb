class AddTwitchUsernameIndex < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :users, :twitch_username, algorithm: :concurrently
  end
end
