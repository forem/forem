class AddDiscordLoginIndexToUser < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :users, :discord_username, algorithm: :concurrently
  end
end
