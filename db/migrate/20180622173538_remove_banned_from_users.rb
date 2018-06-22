class RemoveBannedFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :banned
  end
end
