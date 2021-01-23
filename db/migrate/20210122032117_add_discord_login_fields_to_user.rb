class AddDiscordLoginFieldsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :discord_username, :string
    add_column :users, :discord_created_at, :datetime
  end
end
