class AddTwitchLoginToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :twitch_username, :string
    add_column :users, :twitch_created_at, :datetime
  end
end
