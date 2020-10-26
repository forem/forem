class AddFacebookLoginFields < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :facebook_username, :string
    add_column :users, :facebook_created_at, :datetime
  end
end
