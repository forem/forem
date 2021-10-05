class AddForemUsernameToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :forem_username, :string
  end
end
