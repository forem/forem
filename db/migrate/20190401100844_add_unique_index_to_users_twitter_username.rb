class AddUniqueIndexToUsersTwitterUsername < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :twitter_username, unique: true
  end
end
