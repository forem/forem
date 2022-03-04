class AddInstagramUrlToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :instagram_url, :string
  end
end
