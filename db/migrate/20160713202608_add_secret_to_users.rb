class AddSecretToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :secret, :string
  end
end
