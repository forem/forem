class AddDestroyTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :destroy_token, :string
  end
end
