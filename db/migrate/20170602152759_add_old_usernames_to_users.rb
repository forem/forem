class AddOldUsernamesToUsers < ActiveRecord::Migration
  def change
    add_column :users,    :old_username, :string
    add_column :users,    :old_old_username, :string
  end
end
