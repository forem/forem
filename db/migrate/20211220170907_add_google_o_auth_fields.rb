class AddGoogleOAuthFields < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :google_username, :string
    add_column :users, :google_created_at, :datetime
  end
end
