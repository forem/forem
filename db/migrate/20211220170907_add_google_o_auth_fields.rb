class AddGoogleOAuthFields < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :google_oauth2_username, :string
    add_column :users, :google_oauth2_created_at, :datetime
  end
end
