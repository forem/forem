class AddOldUsernamesToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users,    :old_username, :string
    add_column :users,    :old_old_username, :string
  end
end
