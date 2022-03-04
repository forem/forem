class AddRememberTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :remember_token, :string
  end
end
