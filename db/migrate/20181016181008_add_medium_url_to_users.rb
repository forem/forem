class AddMediumUrlToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :medium_url, :string
  end
end
