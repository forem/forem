class AddContentPreferencesToUsersSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :users_settings, :content_preferences_input, :text
    add_column :users_settings, :content_preferences_updated_at, :datetime
  end
end
