class RenameAuthorsToUsers < ActiveRecord::Migration[4.2]
  def change
    rename_table :authors, :users
  end
end
