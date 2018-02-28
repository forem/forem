class RenameAuthorsToUsers < ActiveRecord::Migration
  def change
    rename_table :authors, :users
  end
end
