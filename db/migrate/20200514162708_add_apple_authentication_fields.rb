class AddAppleAuthenticationFields < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :apple_created_at, :datetime
    add_column :users, :apple_username, :string
  end
end
