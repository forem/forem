class AddTwitchUrlToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :twitch_url, :string
  end
end
